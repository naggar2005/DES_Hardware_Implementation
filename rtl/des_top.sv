module des_top (
    input  logic        clk,
    input  logic        arstn,

    input  logic        start,
    input  logic        mode,

    input  logic [63:0] key,
    input  logic [63:0] data_in,

    output logic [63:0] data_out,
    output logic        busy,
    output logic        done
);

/*
    controller:
        inputs: start (External control)
        outputs: 
                busy , done (External control)
                #load , #round_en , #finalize , #round_index (Datapath control)

    data_path:
        inputs: 
                data_in , key , mode 
                #load , #round_en , #finalize , #round_index (controller commands)

        outpits:
                data_out  

*/

    logic load , round_en;
    logic finalize;
    logic [3:0] round_index;

    controller Controller (
        .clk(clk)                   ,
        .arstn(arstn)               ,
        .start(start)               ,
        .load(load)                 ,
        .round_en(round_en)         ,
        .finalize(finalize)         ,
        .round_index(round_index)   ,
        .busy(busy)                 ,
        .done(done)                 
    );


    data_path Data_Path(
        .clk(clk)                   ,
        .arstn(arstn)               ,
        .data_in(data_in)           ,
        .key(key)                   ,
        .mode(mode)                 ,
        .load(load)                 ,
        .round_en(round_en)         ,
        .finalize(finalize)         ,
        .round_index(round_index)   ,
        .data_out(data_out)         
    );


endmodule