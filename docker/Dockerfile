# import from ubuntu 20.04
FROM ubuntu:20.04
LABEL maintainer="Jue Wang <wangjue46@huawei.com>"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y python3 python3-pip cmake vim git gcc clang \
    python3-dev python3-setuptools llvm lcov zip unzip lsb-release wget software-properties-common gnupg \    
    binutils-dev libunwind-dev libblocksruntime-dev  \   
    doxygen bear graphviz
RUN pip3 install --no-cache-dir boto3 mysql-connector-python==8.0.5 six pyYAML utils cxxfilt jinja2 requests
RUN mkdir /FuzzingSubjects
WORKDIR /FuzzingTools
RUN wget https://apt.llvm.org/llvm.sh &&   \  
    chmod +x llvm.sh &&  \   
    ./llvm.sh 15 all
COPY . .
RUN chmod +x ./update-alternatives-clang.sh &&  \   
    ./update-alternatives-clang.sh 15 100
RUN git clone https://github.com/AFLplusplus/AFLplusplus.git &&   \  
    cd AFLplusplus && \    
    make distrib
RUN apt-add-repository universe &&  \   
    apt-get update && \    
    apt-get install -y doxygen
RUN cp legion.sh /FuzzingSubjects &&  \ 
    cp libstd* /usr/lib/x86_64-linux-gnu/ && \
    rm llvm.sh update-alternatives-clang.sh Dockerfile libstd*
ENV PATH="/FuzzingTools/radamsa:/FuzzingTools/honggfuzz/hfuzz_cc:/FuzzingTools/honggfuzz:/FuzzingTools/AFLplusplus:/FuzzingTools/Legion/bin:/FuzzingTools/Legion/scripts:$PATH"
RUN echo YES | afl-persistent-config