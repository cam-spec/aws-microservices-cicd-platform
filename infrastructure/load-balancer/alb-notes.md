# Application Load Balancer Notes

## Planned Routing
- / -> customer-service
- /suppliers -> customer-service
- /admin/suppliers -> employee-service

## Planned AWS Components
- ALB
- Target groups
- ECS services
- Listener rules
