package com.example.demo.controller;

import com.example.demo.model.Produit;
import com.example.demo.service.ProduitService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/produits")
public class ProduitController {
    private final ProduitService service;
    public ProduitController(ProduitService service) { this.service = service; }

    @GetMapping
    public String list(Model m) {
        m.addAttribute("produits", service.listAll());
        return "produits";
    }

    @GetMapping("/new")
    public String form(Model m) {
        m.addAttribute("produit", new Produit());
        return "produit-form";
    }

    @PostMapping
    public String save(@ModelAttribute Produit produit) {
        service.save(produit);
        return "redirect:/produits";
    }

    @GetMapping("/delete/{id}")
    public String delete(@PathVariable Long id) {
        service.delete(id);
        return "redirect:/produits";
    }
}
