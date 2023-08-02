#include <iostream>
#include <fstream>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>
#include "hash_set.h"

using namespace std;

#define INITIAL_SEED 14;

extern uint32_t* random_mark_for_tracing_jue;
extern string* function_name_for_tracing_jue;
extern size_t tracing_array_size_jue;
extern uint32_t seed;

hash_set* paths;

extern "C" {
    int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size);
}


void readFile(string fileName, uint8_t*& buffer, size_t& bufferSize) {
    ifstream inputFile(fileName, ios::binary);

    if (inputFile.is_open())
    {
        inputFile.seekg(0, ios::end);
        size_t fileLength = inputFile.tellg();
        inputFile.seekg(0, ios::beg);

        bufferSize = fileLength;
        buffer = new uint8_t[bufferSize];

        inputFile.read(reinterpret_cast<char*>(buffer), bufferSize);
        inputFile.close();
    }
    
}


void run_single_test(string fileName) {
    uint8_t* buffer;
    size_t bufferSize;

    readFile(fileName, buffer, bufferSize);

    seed = INITIAL_SEED;

   // printf("INITIAL Seed: %u\n", seed);
    LLVMFuzzerTestOneInput(buffer, bufferSize);
   // printf("final seed: %u\n",seed);
    insert(paths, seed);

    delete[] buffer;

}


void run_tests(const char *dir_path) {
    DIR *dir;
    struct dirent *entry;
    char file_path[PATH_MAX];
    int count = 0;

    if ((dir = opendir(dir_path))!= NULL)
    {
        while ((entry = readdir(dir)) != NULL)
        {   
            if (entry->d_type == DT_REG)
            {   
                count++;
                if (count % 100 ==0) {
                    cout << "processing seed #" << count << endl;
                }
                
             //   cout << "processing seed #" << count++ << endl;
                //file_path = (char*) malloc(strlen(dir_path) + strlen(entry->d_name) + 2);
                sprintf(file_path, "%s/%s",dir_path, entry->d_name );
                //printf("%s\n", file_path);
                run_single_test(file_path);
            }
            
        }
        
    } else {
        perror("");
    }
    
    
}



int main(int argc, char** argv) {

    if (argc < 3)
    {
        cout << "Usage: " << argv[0] << " <folder_path> <report_path>" << endl;
        return 1;
    }
    

    char* dir_path = argv[1];

    paths = create_hash_set();
    
    run_tests(dir_path);
    
    string file_name = argv[2];
    ofstream output(file_name);

    if (output.is_open())
    {
        output << "[EDGE]" << endl;
        for (size_t i = 1; i <= tracing_array_size_jue; i++)
        {

          //  printf("%lu %u\n", i, random_mark_for_tracing_jue[i]);
            output << i << " " << random_mark_for_tracing_jue[i] << endl;
            
        }

      //  printf("cover %u edges out of %lu\n", edges, tracing_array_size_jue);
        output << "[PATH]" << endl;
        uint32_t** array = hashset_to_array(paths);
        uint32_t count = 0;
        for (int i = 0; i < paths->size; i++)
        {
            output << array[0][i] << " " << array[1][i] << endl;            
            //printf("path hashcode: %u, count: %u\n", array[0][i], array[1][i]);
            count += array[1][i];
        }
        //printf("Distinct paths: %u, Overall paths: %u\n", paths->size, count);
        free_hash_set(paths);

        output << "[EDGE TO FUNC]" << endl;
        for (size_t i = 1; i < tracing_array_size_jue; i++)
        {
            if (function_name_for_tracing_jue[i] != "")
            {
                output <<i << " " << function_name_for_tracing_jue[i] << endl;
            }
            
            
        }
        output.close();
    } else {
        cout << "[ERROR] faile to create file to write!!" << endl;
    }

    return 0;
}