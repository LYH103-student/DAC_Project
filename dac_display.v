
module dac_display (
    input wire clk,
    input wire rst,
    input wire btn1,
    input wire btn3,
    input wire btn4,
    input wire btn6,
    input wire btn7,
    input wire btn9,

    output wire [9:0] dac_data,

    // 7-segment
    output reg [6:0] seg,
    output reg [3:0] an,

    // Text LCD (8-bit)
    output reg LCD_E,
    output reg LCD_RS,
    output wire LCD_RW,
    output reg [7:0] LCD_DATA
);

    // DAC controller from part D
    dac_control u_dac (
        .clk(clk),
        .rst(rst),
        .btn1(btn1),
        .btn3(btn3),
        .btn4(btn4),
        .btn6(btn6),
        .btn7(btn7),
        .btn9(btn9),
        .dac_data(dac_data)
    );

    // Convert DAC value to decimal digits
    reg [3:0] d0, d1, d2, d3;
    integer value;

    always @(*) begin
        value = dac_data;
        d3 = value / 1000;
        d2 = (value / 100) % 10;
        d1 = (value / 10) % 10;
        d0 = value % 10;
    end

    // 7-segment decoder (active low)
    function [6:0] seg_decode;
        input [3:0] digit;
        begin
            case (digit)
                0: seg_decode = 7'b1000000;
                1: seg_decode = 7'b1111001;
                2: seg_decode = 7'b0100100;
                3: seg_decode = 7'b0110000;
                4: seg_decode = 7'b0011001;
                5: seg_decode = 7'b0010010;
                6: seg_decode = 7'b0000010;
                7: seg_decode = 7'b1111000;
                8: seg_decode = 7'b0000000;
                9: seg_decode = 7'b0010000;
                default: seg_decode = 7'b1111111;
            endcase
        end
    endfunction

    // 7-segment multiplexing
    reg [15:0] scan_count = 0;
    reg [3:0] selected_digit;

    always @(posedge clk or posedge rst) begin
        if (rst)
            scan_count <= 0;
        else
            scan_count <= scan_count + 1'b1;
    end

    always @(*) begin
        case (scan_count[11:10])
            2'd0: begin
                an = 4'b1110;
                selected_digit = d0;
            end
            2'd1: begin
                an = 4'b1101;
                selected_digit = d1;
            end
            2'd2: begin
                an = 4'b1011;
                selected_digit = d2;
            end
            default: begin
                an = 4'b0111;
                selected_digit = d3;
            end
        endcase

        seg = seg_decode(selected_digit);
    end

    // LCD controller
    // Assumes clk = 1 MHz
    localparam [2:0]
        INIT_WAIT = 3'd0,
        INIT_FUNC = 3'd1,
        INIT_DISP = 3'd2,
        INIT_ENTRY = 3'd3,
        LCD_WRITE = 3'd4;

    reg [2:0] lcd_state = INIT_WAIT;
    reg [15:0] lcd_timer = 0;
    reg [5:0] lcd_index = 0;
    reg [7:0] lcd_char;

    assign LCD_RW = 1'b0;

    // LCD text (16x2)
    always @(*) begin
        lcd_char = 8'h20;

        case (lcd_index)
            // Line 1
            0: lcd_char = 8'h80;
            1: lcd_char = "D";
            2: lcd_char = "A";
            3: lcd_char = "C";
            4: lcd_char = " ";
            5: lcd_char = "I";
            6: lcd_char = "N";
            7: lcd_char = "P";
            8: lcd_char = "U";
            9: lcd_char = "T";
            10: lcd_char = " ";
            11: lcd_char = "V";
            12: lcd_char = "A";
            13: lcd_char = "L";
            14: lcd_char = "U";
            15: lcd_char = "E";

            // Line 2
            16: lcd_char = 8'hC0;
            17: lcd_char = "V";
            18: lcd_char = "A";
            19: lcd_char = "L";
            20: lcd_char = "U";
            21: lcd_char = "E";
            22: lcd_char = ":";
            23: lcd_char = " ";
            24: lcd_char = 8'h30 + d3;
            25: lcd_char = 8'h30 + d2;
            26: lcd_char = 8'h30 + d1;
            27: lcd_char = 8'h30 + d0;
            default: lcd_char = 8'h20;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lcd_state <= INIT_WAIT;
            lcd_timer <= 0;
            lcd_index <= 0;
            LCD_E <= 0;
            LCD_RS <= 0;
            LCD_DATA <= 0;
        end
        else begin
            case (lcd_state)
                INIT_WAIT: begin
                    LCD_E <= 0;
                    if (lcd_timer == 15000) begin
                        lcd_timer <= 0;
                        lcd_state <= INIT_FUNC;
                    end
                    else
                        lcd_timer <= lcd_timer + 1;
                end

                INIT_FUNC: begin
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h38;
                    LCD_E <= 1;
                    if (lcd_timer == 50) begin
                        LCD_E <= 0;
                        lcd_timer <= 0;
                        lcd_state <= INIT_DISP;
                    end
                    else
                        lcd_timer <= lcd_timer + 1;
                end

                INIT_DISP: begin
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h0C;
                    LCD_E <= 1;
                    if (lcd_timer == 50) begin
                        LCD_E <= 0;
                        lcd_timer <= 0;
                        lcd_state <= INIT_ENTRY;
                    end
                    else
                        lcd_timer <= lcd_timer + 1;
                end

                INIT_ENTRY: begin
                    LCD_RS <= 0;
                    LCD_DATA <= 8'h06;
                    LCD_E <= 1;
                    if (lcd_timer == 50) begin
                        LCD_E <= 0;
                        lcd_timer <= 0;
                        lcd_state <= LCD_WRITE;
                    end
                    else
                        lcd_timer <= lcd_timer + 1;
                end

                LCD_WRITE: begin
                    if (lcd_timer == 0) begin
                        LCD_E <= 0;
                        LCD_DATA <= lcd_char;
                        LCD_RS <=
                            (lcd_index != 0 &&
                             lcd_index != 16);
                    end

                    if (lcd_timer == 10)
                        LCD_E <= 1;

                    if (lcd_timer == 50)
                        LCD_E <= 0;

                    if (lcd_timer == 100) begin
                        lcd_timer <= 0;

                        if (lcd_index == 27)
                            lcd_index <= 0;
                        else
                            lcd_index <= lcd_index + 1;
                    end
                    else
                        lcd_timer <= lcd_timer + 1;
                end
            endcase
        end
    end

endmodule
