#define AL(x) __attribute__((weak, alias("alias_func"))) void x(void);

__attribute__((weak)) __attribute__((no_instrument_function)) void alias_func(void) {
}

AL(__cyg_profile_func_enter)
AL(__cyg_profile_func_exit)
AL(__sanitizer_cov_trace_pc)
AL(__sanitizer_cov_trace_const_cmp1)
AL(__sanitizer_cov_trace_const_cmp2)
AL(__sanitizer_cov_trace_const_cmp4)
AL(__sanitizer_cov_trace_const_cmp8)
AL(__sanitizer_cov_trace_cmp1)
AL(__sanitizer_cov_trace_cmp2)
AL(__sanitizer_cov_trace_cmp4)
AL(__sanitizer_cov_trace_cmp8)
AL(__sanitizer_cov_trace_switch)
AL(__sanitizer_cov_trace_cmpd)
AL(__sanitizer_cov_trace_cmpf)
AL(__asan_report_store1)
AL(__asan_report_store2)
AL(__asan_report_store4)
AL(__asan_report_store8)
AL(__asan_report_store16)
AL(__asan_report_load1)
AL(__asan_report_load2)
AL(__asan_report_load4)
AL(__asan_report_load8)
AL(__asan_report_load16)
AL(__asan_register_globals)
AL(__asan_unregister_globals)
AL(__asan_init)
AL(__asan_version_mismatch_check_v8)
AL(__asan_handle_no_return)
AL(__asan_option_detect_stack_use_after_return)
AL(__asan_stack_malloc_1)
AL(__asan_stack_malloc_2)
AL(__asan_stack_malloc_3)
AL(__asan_stack_malloc_4)
AL(__asan_stack_malloc_5)
AL(__asan_stack_malloc_6)
AL(__asan_stack_malloc_7)
AL(__asan_stack_free_5)
AL(__asan_stack_free_6)
AL(__asan_stack_free_7)
AL(__asan_report_load_n)
AL(__asan_report_store_n)
AL(__asan_alloca_poison)
AL(__asan_allocas_unpoison)
AL(__asan_poison_stack_memory)
AL(__asan_unpoison_stack_memory)