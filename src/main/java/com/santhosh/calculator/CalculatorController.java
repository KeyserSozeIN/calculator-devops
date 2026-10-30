package com.santhosh.calculator;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class CalculatorController {

    private final CalculatorService service;

    public CalculatorController(CalculatorService service) {
        this.service = service;
    }

    @GetMapping("/add")
    public Map<String, Object> add(@RequestParam double a, @RequestParam double b) {
        return response("add", a, b, service.add(a, b));
    }

    @GetMapping("/subtract")
    public Map<String, Object> subtract(@RequestParam double a, @RequestParam double b) {
        return response("subtract", a, b, service.subtract(a, b));
    }

    @GetMapping("/multiply")
    public Map<String, Object> multiply(@RequestParam double a, @RequestParam double b) {
        return response("multiply", a, b, service.multiply(a, b));
    }

    @GetMapping("/divide")
    public Map<String, Object> divide(@RequestParam double a, @RequestParam double b) {
        return response("divide", a, b, service.divide(a, b));
    }

    // Whole numbers are shown as 5 instead of 5.0
    private Map<String, Object> response(String op, double a, double b, double result) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("operation", op);
        body.put("a", clean(a));
        body.put("b", clean(b));
        body.put("result", clean(result));
        return body;
    }

    private Number clean(double v) {
        if (v == Math.rint(v) && !Double.isInfinite(v) && Math.abs(v) < 1e15) {
            return (long) v;
        }
        return v;
    }
}
