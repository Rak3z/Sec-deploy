## 1. Inicialización y Configuración
- `terraform init` → Inicializa un directorio de trabajo con el backend y los módulos necesarios.
- `terraform validate` → Valida la sintaxis y configuración del código Terraform.
- `terraform fmt` → Formatea el código para mantener un estilo consistente.

## 2. Planificación y Aplicación
- `terraform plan` → Muestra un plan de ejecución sin aplicarlo, permitiendo revisar los cambios antes de ejecutarlos.
- `terraform apply` → Aplica los cambios descritos en el plan de ejecución.
- `terraform apply -auto-approve` → Aplica los cambios sin pedir confirmación.

## 3. Gestión del Estado
- `terraform state list` → Lista los recursos gestionados en el estado.
- `terraform state show <resource>` → Muestra los detalles de un recurso específico en el estado.
- `terraform state rm <resource>` → Elimina un recurso del estado sin destruirlo en la infraestructura.
- `terraform refresh` → Sincroniza el estado con la infraestructura real.

## 4. Destrucción de Recursos
- `terraform destroy` → Elimina todos los recursos gestionados por Terraform.
- `terraform destroy -target=<resource>` → Destruye un recurso específico sin afectar al resto.

## 5. Módulos y Variables
- `terraform output` → Muestra los valores de salida definidos en la configuración.
- `terraform output <variable>` → Muestra el valor de una variable de salida específica.
- `terraform taint <resource>` → Marca un recurso para ser recreado en la siguiente ejecución de `apply`.

## 6. Depuración y Diagnóstico
- `terraform graph` → Genera un gráfico de dependencias en formato DOT.
- `terraform version` → Muestra la versión de Terraform instalada.
- `terraform providers` → Lista los proveedores usados en la configuración.
