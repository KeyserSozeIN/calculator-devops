package com.santhosh.calculator;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class CalculatorServiceTest {

    private final CalculatorService service = new CalculatorService();

    @Test
    void addWorks() {
        assertEquals(5.0, service.add(2, 3));
        assertEquals(-1.0, service.add(2, -3));
    }

    @Test
    void subtractWorks() {
        assertEquals(-1.0, service.subtract(2, 3));
        assertEquals(5.0, service.subtract(2, -3));
    }

    @Test
    void multiplyWorks() {
        assertEquals(6.0, service.multiply(2, 3));
        assertEquals(0.0, service.multiply(0, 99));
    }

    @Test
    void divideWorks() {
        assertEquals(2.5, service.divide(5, 2));
        assertEquals(-2.0, service.divide(6, -3));
    }

    @Test
    void divideByZeroThrows() {
        ArithmeticException ex = assertThrows(ArithmeticException.class, () -> service.divide(1, 0));
        assertEquals("Division by zero is not allowed", ex.getMessage());
    }
}
