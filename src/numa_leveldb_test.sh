#! /bin/sh

#value_array=(1024 4096 16384 65536)
value_array=(4096)
test_all_size=81920000000   #80G


bench_db_path="/pmem/ceshi"
bench_value="4096"
write_buffer_size="`expr 64 \* 1024 \* 1024`"  

#bench_benchmarks="fillseq,stats,readseq,readrandom,stats" #"fillrandom,fillseq,readseq,readrandom,stats"
#bench_benchmarks="fillrandom,stats,readseq,readrandom,stats"
#bench_benchmarks="fillrandom,stats,wait,stats,readseq,readrandom,readrandom,readrandom,stats"
#bench_benchmarks="fillrandom,stats,readseq,readrandom,stats"
bench_benchmarks="fillrandom,stats,readrandom,stats"
#bench_benchmarks="fillseq,stats"
bench_num="20000000"
bench_readnum="1000000"

report_write_latency="1"


bench_file_path="$PWD/db_bench"
bench_file_dir="$PWD"

if [ ! -f "${bench_file_path}" ];then
bench_file_path="$(dirname $PWD )/db_bench"
bench_file_dir="$(dirname $PWD )"
fi

if [ ! -f "${bench_file_path}" ];then
echo "Error:${bench_file_path} or $(dirname $PWD )/db_bench not find!"
exit 1
fi

RUN_ONE_TEST() {
    const_params="
        --db=$bench_db_path \
        --value_size=$bench_value \
        --benchmarks=$bench_benchmarks \
        --num=$bench_num \
        --reads=$bench_readnum \
        --write_buffer_size=$write_buffer_size \
        --report_write_latency=$report_write_latency \
    "
    cmd="numactl -N 1 -m 1 $bench_file_path $const_params >>out.out 2>&1"
    echo $cmd >out.out
    echo $cmd
    eval $cmd
}

CLEAN_CACHE() {
    if [ -n "$bench_db_path" ];then
        rm -f $bench_db_path/*
    fi
    sleep 2
    sync
    echo 3 > /proc/sys/vm/drop_caches
    sleep 2
}

COPY_OUT_FILE(){
    mkdir $bench_file_dir/result > /dev/null 2>&1
    res_dir=$bench_file_dir/result/value-$bench_value
    mkdir $res_dir > /dev/null 2>&1
    \cp -f $bench_file_dir/Latency.csv $res_dir/
    \cp -f $bench_file_dir/out.out $res_dir/
}
RUN_ALL_TEST() {
    for value in ${value_array[@]}; do
        CLEAN_CACHE
        bench_value="$value"
        bench_num="`expr $test_all_size / $bench_value`"

        RUN_ONE_TEST
        if [ $? -ne 0 ];then
            exit 1
        fi
        COPY_OUT_FILE
        sleep 5
    done
}

RUN_ALL_TEST
