module digital_filter(

    input wire clk,
    input wire reset,
    input wire [7:0] moisture,

    output wire [7:0] filtered_moisture

);

reg [7:0] s0, s1, s2, s3;
reg [9:0] sum;

// Shift Register
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        s0 <= 0;
        s1 <= 0;
        s2 <= 0;
        s3 <= 0;
    end
    else
    begin
        s3 <= s2;
        s2 <= s1;
        s1 <= s0;
        s0 <= moisture;
    end
end

// Sum of four samples
always @(*)
begin
    sum = s0 + s1 + s2 + s3;
end

// Divide by 4
assign filtered_moisture = sum >> 2;

endmodule