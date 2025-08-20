`timescale 1ns / 1ps

module tb_temperature_monitor;

    reg clk = 0;
    reg start = 0;
    wire [7:0] temperature;
    wire ready;

    // SPI signals
    wire mosi, sclk, cs;
    reg miso;

    // Instantiate the DUT (Device Under Test)
    temperature_monitor uut (
        .clk(clk),
        .start(start),
        .temperature(temperature),
        .ready(ready)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Simulate SPI ADC behavior
    reg [9:0] adc_mock_value = 10'd250; // Example ADC value (250 * 4.88mV ≈ 1.22V)
    integer i;

    initial begin
        $display("Starting simulation...");
        $dumpfile("tb_temperature_monitor.vcd");
        $dumpvars(0, tb_temperature_monitor);

        // Wait for a few clock cycles
        #20;

        // Trigger ADC read
        start <= 1;
        #10;
        start <= 0;

        // Wait for CS to go low (ADC selected)
        wait (uut.adc.cs == 0);

        // Simulate SPI data transfer (MSB first)
        for (i = 9; i >= 0; i = i - 1) begin
            wait (uut.adc.sclk == 1); // Wait for rising edge
            miso <= adc_mock_value[i]; // Provide bit
            wait (uut.adc.sclk == 0); // Wait for falling edge
        end

        // Wait for ready signal
        wait (ready == 1);
        $display("Temperature Output: %d °C", temperature);

        #20;
        $finish;
    end

endmodule
