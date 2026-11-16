// Seul fichier à modifier quand le portail change de machine (VM, puis AWS).
// "host" vide = même machine que celle qui sert cette page (marche tel quel sur la VM et sur AWS).
window.PORTAIL = {
  host: "",
  outils: [
    { nom: "Jenkins",    port: 8080, proto: "http",  role: "Pipeline CI/CD : tests, secrets, build, scan, déploiement." },
    { nom: "Grafana",    port: 3000, proto: "http",  role: "Tableaux de bord : état de la machine en temps réel." },
    { nom: "Prometheus", port: 9090, proto: "http",  role: "Collecte des métriques et état des cibles." },
    { nom: "Wazuh",      port: 443,  proto: "https", role: "Détection d'intrusion et alertes de sécurité." },
    { nom: "Application",port: 5000, proto: "http",  role: "L'application Flask déployée par le pipeline." }
  ]
};
