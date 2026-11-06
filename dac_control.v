
module dac_control (
    input wire clk,
    input wire rst,
    input wire btn1,
    input wire btn3,
    input wire btn4,
    input wire btn6,
    input wire btn7,
    input wire btn9,
    output reg [9:0] dac_data
);

    reg [5:0] btn_prev;

    wire [5:0] btn_now =
        {btn9, btn7, btn6, btn4, btn3, btn1};

    wire [5:0] pressed = btn_now & ~btn_prev;

    reg [9:0] next_data;

    always @(*) begin
        next_data = dac_data;

        if (pressed[0]) begin
            if (dac_data >= 1)
                next_data = dac_data - 10'd1;
            else
                next_data = 10'd0;
        end
        else if (pressed[1]) begin
            if (dac_data <= 1022)
                next_data = dac_data + 10'd1;
            else
                next_data = 10'd1023;
        end
        else if (pressed[2]) begin
            if (dac_data >= 2)
                next_data = dac_data - 10'd2;
            else
                next_data = 10'd0;
        end
        else if (pressed[3]) begin
            if (dac_data <= 1021)
                next_data = dac_data + 10'd2;
            else
                next_data = 10'd1023;
        end
        else if (pressed[4]) begin
            if (dac_data >= 8)
                next_data = dac_data - 10'd8;
            else
                next_data = 10'd0;
        end
        else if (pressed[5]) begin
            if (dac_data <= 1015)
                next_data = dac_data + 10'd8;
            else
                next_data = 10'd1023;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dac_data <= 10'd0;
            btn_prev <= 6'b000000;
        end
        else begin
            btn_prev <= btn_now;
            dac_data <= next_data;
        end
    end

endmodule
