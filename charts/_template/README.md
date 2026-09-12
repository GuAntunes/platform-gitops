# Chart template

Copie com `make new-chart NAME=<nome>` ou manualmente:

```bash
cp -R charts/_template charts/<nome>
# Edite Chart.yaml (name, description) e adicione templates/
```

Estrutura esperada: `values.yaml`, `base/values.yaml`, `overlays/{dev,staging,prod}/values.yaml`.
