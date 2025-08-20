`timescale 1ns / 1ps

// Project Name: temperature_monitor 
module spi_adc(
    input wire clk,             // System clock
    input wire start,           // Start signal for reading ADC
    output reg [9:0] adc_value, // ADC output value
    output reg ready            // Indicates when data is ready
);

    reg [2:0] state;
    reg [2:0] count;
    reg [7:0] shift_reg;        // Shift register for SPI data
    reg mosi;                   // Master Out Slave In
    reg miso;                   // Master In Slave Out
    reg sclk;                   // SPI Clock
    reg cs;                     // Chip Select (active low)

    // SPI state machine
    always @(posedge clk) begin
        case (state)
            0: begin // Idle state
                ready <= 0;
                cs <= 1; // Deselect the ADC
                if (start) begin
                    state <= 1;
                end
            end
            1: begin // Select ADC
                cs <= 0; // Select the ADC
                count <= 0;
                state <= 2;
            end
            2: begin // Shift data in
                if (count < 8) begin
                    sclk <= 1; // Clock high
                    mosi <= 0; // Send 0 to start conversion
                    count <= count + 1;
                    state <= 3;
                end else begin
                    state <= 5; // Go to read state
                end
            end
            3: begin
                sclk <= 0; // Clock low
                if (count < 8) begin
                    shift_reg <= {shift_reg[6:0], miso}; // Shift in data
                    state <= 2; // Go to shift state
                end else begin
                    adc_value <= shift_reg; // Store ADC value
                    state <= 4; // Go to complete state
                end
            end
            4: begin // Complete
                cs <= 1; // Deselect the ADC
                ready <= 1; // Indicate ready
                state <= 0; // Go back to idle
            end
        endcase
    end

endmodule


module temperature_monitor(
    input wire clk,
    input wire start,
    output reg [7:0] temperature, // 0-255 degrees (assuming 0-255°C)
    output wire ready
);

    wire [9:0] adc_value;
    spi_adc adc (
        .clk(clk),
        .start(start),
        .adc_value(adc_value),
        .ready(ready)
    );

    always @(posedge clk) begin
        if (ready) begin
            // Assuming 10mV/°C for LM35, scale accordingly
            temperature <= adc_value[9:2]; // Convert ADC value to temperature
        end
    end

endmodule
