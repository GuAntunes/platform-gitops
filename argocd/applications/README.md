# Applications

Organize por projeto e ambiente:

```
applications/
└── <projeto>/
    └── <ambiente>/
        └── <app>.yaml
```

Exemplo: `applications/my-project/dev/api.yaml`

O `root-app` descobre todos os YAMLs recursivamente (`directory.recurse: true`).
