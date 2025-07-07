# 🎤 GUION DE EXPOSICIÓN AWS - CHAMBA PE
## Exposición Técnica Clara y Conciso (8 minutos)

---

## 🎬 **PARTE 1 - PERSONA A (0:00 - 4:00)**

### **Slide 1: Presentación y Contexto (0:00 - 0:45)**

**Persona A:** 
"Hola, soy [Nombre A], co-fundador de ChambaPe. 

ChambaPe es un marketplace que conecta técnicos de oficios con clientes en tiempo real. Nuestro desafío técnico: manejar picos de demanda, garantizar seguridad de datos y mantener 99.9% de disponibilidad.

**Objetivos no funcionales:**
- Disponibilidad ≥ 99.9%
- Escalabilidad automática ante picos de demanda
- Seguridad y aislamiento de datos sensibles
- Trazabilidad completa de despliegues

**Flujo de usuario:** Usuario reserva → Backend procesa → ECS ejecuta lógica → Notificación en tiempo real → Feedback post-servicio"

---

### **Slide 2: Infraestructura como Código - AWS CDK (0:45 - 1:30)**

**Persona A:**
"Para garantizar consistencia y velocidad, implementamos AWS CDK en TypeScript.

**Beneficios clave:**
- Infraestructura versionada en Git junto al código
- `cdk synth` genera CloudFormation templates
- `cdk deploy` aplica cambios atómicos con rollback automático
- Tests unitarios con Jest + CDK Assertions validan configuraciones

**Resultado:** Reproducibilidad exacta entre entornos dev, staging y producción, eliminando drift manual y errores de configuración."

---

### **Slide 3: Arquitectura de Red y Seguridad (1:30 - 2:30)**

**Persona A:**
"Implementamos una VPC dedicada (10.0.0.0/16) en dos zonas de disponibilidad para alta disponibilidad.

**Zona Pública (verde en diagrama):**
- Application Load Balancer expone HTTPS (puertos 80/443)
- NAT Gateway único para salida a Internet de recursos privados
- Internet Gateway como punto de entrada

**Zona Privada (roja en diagrama):**
- ECS Fargate tasks ejecutan backend NestJS
- RDS PostgreSQL en subred privada (puerto 5432)

**Security Groups - Principio de mínimo privilegio:**
- ALB SG: permite 443/TCP desde Internet
- ECS SG: permite 3000/TCP solo desde ALB SG
- RDS SG: permite 5432/TCP solo desde ECS SG

**VPC Flow Logs** habilitados para auditoría de tráfico a nivel de subred."

---

### **Slide 4: Almacenamiento y Distribución de Contenido (2:30 - 3:30)**

**Persona A:**
"Para la SPA utilizamos S3 con hosting estático configurado:
- Bucket `chambape-web-<env>` para archivos estáticos
- Versioning activado permite rollback de contenido en segundos
- CloudFront como CDN global con certificado SSL gestionado por ACM

**Almacenamiento de archivos de usuario:**
- Bucket `chambape-uploads-<env>` con Server-Side Encryption (SSE-S3)
- Lifecycle Rules: mover a Glacier tras 30 días, expirar tras 365 días
- Origin Access Identity bloquea accesos directos al bucket

**CloudFront configuración:**
- Cache Policy: TTL altos para estáticos, TTL bajos para API
- Certificado SSL auto-renovable via ACM
- Distribución global para latencia mínima"

---

### **Slide 5: Contenedores y Base de Datos (3:30 - 4:00)**

**Persona A:**
"Backend NestJS ejecuta en Docker multi-stage con imágenes optimizadas (<200 MB):
- ECR como registro privado con Image Scanning integrado
- Lifecycle Policy retiene solo las últimas 10 imágenes

**ECS Fargate (serverless containers):**
- Auto-scaling basado en CPU > 60% y peticiones ALB > 100 req/min
- Rolling updates (minHealthyPercent:50%, maxPercent:200%) garantizan zero downtime
- Health-checks (/health) y swagger docs (/docs) para monitoreo

**RDS PostgreSQL v14 en subred privada:**
- Backups automáticos con retención de 7 días
- Snapshots manuales para puntos de recuperación
- Multi-AZ opcional para replicación sin código adicional"

---

---

## 🎬 **PARTE 2 - PERSONA B (4:00 - 8:00)**

### **Slide 6: Pipeline CI/CD y Gestión de Secretos (4:00 - 5:00)**

**Persona B:**
"Hola, soy [Nombre B]. Nuestro pipeline CI/CD con GitHub Actions:

**Flujo automatizado:**
1. Push en rama main (protegida) dispara workflow
2. `npm ci + npm test` (unit + integración)
3. `docker build` con SHA como tag
4. Login a ECR y push de imagen
5. `cdk deploy --require-approval never` actualiza CloudFormation
6. ECS inicia rolling update automáticamente

**Gestión de secretos:**
- AWS Secrets Manager: credenciales RDS con rotación automática
- AWS SSM Parameter Store: variables de entorno no sensibles
- IAM Roles separados: ExecutionRole (push/pull) y TaskRole (runtime access)"

---

### **Slide 7: Costos y Optimización (5:00 - 6:00)**

**Persona B:**
"Análisis de costos mensuales aproximados:

**Componentes principales:**
- ECS Fargate: ≈ $0.0405/vCPU-h + $0.004445/GB-h RAM
- RDS t3.micro: gratuito en free-tier, luego $0.10/GB-mes
- S3: $0.023/GB-mes
- CloudFront: $0.085/GB en LatAm

**Optimizaciones implementadas:**
- Fargate Spot (–70% descuento) para cargas tolerantes
- Savings Plans para descuentos por volumen
- Aurora Serverless v2 roadmap para escalado de lectura/escritura

**Resultado:** Infraestructura enterprise a costo startup."

---

### **Slide 8: Observabilidad y Monitoreo (6:00 - 7:00)**

**Persona B:**
"Stack de observabilidad completo:

**CloudWatch Metrics & Dashboards:**
- CPU, memoria, latencia, errores 5xx en tiempo real
- Alarmas automáticas con SNS para notificaciones
- Filtros de logs para análisis de errores

**AWS X-Ray:**
- Trazabilidad de peticiones distribuidas
- Detección de cuellos de botella
- Análisis de performance end-to-end

**Health Checks:**
- Endpoint `/health` para monitoreo de disponibilidad
- Swagger docs `/docs` para documentación API
- Integración con Slack/Teams para alertas automáticas

**VPC Flow Logs** para auditoría de tráfico de red."

---

### **Slide 9: Roadmap y Ventajas AWS (7:00 - 8:00)**

**Persona B:**
"Roadmap técnico próximo:

**Próximas implementaciones:**
1. Tests E2E (Cypress) integrados en pipeline
2. WAF + Shield Advanced para protección DDoS
3. Multi-región activa-activa para DR y latencia global
4. Integración con Slack/Microsoft Teams para alertas

**¿Por qué AWS vs alternativas?**

| Componente | Alternativa | Ventaja AWS |
|------------|-------------|-------------|
| CDK | Console manual | Versionado, pruebas, rollback automático |
| VPC + NAT | VPC default | Control granular, SLA alto, sin parches |
| S3 + CloudFront | EC2 + Nginx | 99.999999999% durabilidad, CDN global |
| ECR | Docker Hub | Integración IAM, Image Scanning |
| Fargate | EC2 manual | Serverless, sin mantenimiento |
| RDS | Postgres manual | Backups automáticos, Multi-AZ |

**Conclusión:** AWS nos permite enfocarnos en la experiencia de usuario mientras maneja la infraestructura compleja. ChambaPe está preparado para escalar de forma segura y económica."

---

---

## 🎯 **PUNTOS CLAVE PARA LA EXPOSICIÓN:**

1. **Usar el diagrama visual** - Señalar cada componente mientras se explica
2. **Mantener ritmo constante** - 1 minuto por slide aproximadamente
3. **Enfatizar beneficios técnicos** - Seguridad, escalabilidad, costo
4. **Mostrar flujos de datos** - Seguir las flechas del diagrama
5. **Usar terminología técnica precisa** - CDK, Fargate, RDS, etc.
6. **Concluir con valor de negocio** - Preparado para escalar

**¡Éxito en tu exposición! 🎉** 