# C&N Agentes Inmobiliarios – Base de Datos

Repositorio de la base de datos relacional para el sistema de gestión de ventas y rentas de C&N Agentes Inmobiliarios. Implementado en PostgreSQL y Supabase.

## Descripción general

La base de datos está diseñada para centralizar y administrar la información relacionada con las operaciones comerciales de C&N Agentes Inmobiliarios, incluyendo el registro de clientes, asesores comerciales, propiedades, contratos de arrendamiento y compraventa.

Su diseño permite mantener la integridad y consistencia de la información mediante relaciones entre entidades, restricciones, funciones y triggers que automatizan procesos y validan las operaciones realizadas.

## Tecnologías utilizadas

| Tecnología | Aplicación |
|---|---|
| PostgreSQL | Sistema de gestión de bases de datos relacional. |
| Supabase | Alojamiento y administración de la base de datos. |
| pgAdmin 4 | Administración y ejecución de consultas SQL. |
| SQL | Definición, manipulación y gestión de datos. |

## Modelo de datos

La base de datos está conformada por 9 tablas principales:

| Tabla | Descripción |
|---|---|
| `DOCUMENT_TYPE` | Catálogo de tipos de documentos. |
| `NEIGHBORHOOD` | Registro de barrios. |
| `SALES_CONSULTANT` | Información de asesores comerciales. |
| `CUSTOMER` | Registro de clientes. |
| `PROPERTY` | Información de propiedades inmobiliarias. |
| `CONTRACT_RENTAL` | Administración de contratos de arrendamiento. |
| `CONTRACT_SALE` | Administración de contratos de compraventa. |
| `CLAUSE` | Gestión de cláusulas contractuales. |
| `AUDIT_LOG` | Registro de eventos de auditoría. |

## Funcionalidades principales

- Gestión de clientes y asesores comerciales.
- Registro y clasificación de propiedades.
- Administración de operaciones de venta y arrendamiento.
- Gestión de contratos y cláusulas.
- Validación de operaciones mediante funciones y triggers.
- Actualización automática de estados de las propiedades.
- Registro de eventos para auditoría y seguimiento.

## Datos de prueba

Se incorporan registros de prueba para facilitar la validación y el funcionamiento de la base de datos:

- 20 barrios.
- 20 asesores comerciales.
- 1.000 clientes.
- 2.000 propiedades.
- Registros de contratos y cláusulas.

## Estructura del repositorio

```text
cn-inmobiliaria-database/
│
├── database/
│   ├── schema.sql
│   ├── functions.sql
│   └── seed.sql
│
├── docs/
│   ├── DER.png
│   └── diccionario-datos.md
│
├── README.md
└── LICENSE
```

## Instalación y configuración

Para implementar la base de datos en PostgreSQL:

1. Disponer de una instancia de PostgreSQL o un proyecto de Supabase.
2. Configurar la conexión mediante pgAdmin 4.
3. Ejecutar los scripts SQL en el orden correspondiente.
4. Verificar la creación de las tablas, relaciones, funciones y triggers.
5. Comprobar la inserción de los registros de prueba.

**Nota:** Los scripts deben ejecutarse en un entorno preparado para su instalación. No se recomienda ejecutar instrucciones destructivas sobre bases de datos compartidas o en producción.

## Seguridad

- No publicar contraseñas ni credenciales de conexión.
- No incluir información personal real de clientes.
- Utilizar datos ficticios para pruebas y demostraciones.
- Mantener protegidas las credenciales de acceso a Supabase.

## Objetivo

Implementar una base de datos relacional que permita gestionar de manera organizada, consistente y eficiente las operaciones comerciales de C&N Agentes Inmobiliarios, aplicando principios de diseño de bases de datos y automatización mediante PostgreSQL.

---

**C&N Agentes Inmobiliarios**  
*Database Engineering | PostgreSQL | Supabase*
