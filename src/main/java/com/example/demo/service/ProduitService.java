package com.example.demo.service;

import com.example.demo.model.Produit;
import com.example.demo.repository.ProduitRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ProduitService {
    private final ProduitRepository repo;
    public ProduitService(ProduitRepository repo) { this.repo = repo; }

    public List<Produit> listAll()   { return repo.findAll(); }
    public Produit get(Long id)      { return repo.findById(id).orElse(null); }
    public Produit save(Produit p)   { return repo.save(p); }
    public void delete(Long id)      { repo.deleteById(id); }
}
