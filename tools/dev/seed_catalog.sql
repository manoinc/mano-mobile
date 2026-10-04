-- Dev-only catalog seed for a local gateway backed by Postgres; categories match the app's rail ids.
BEGIN;
TRUNCATE job_service_offers, job_service_revisions, job_services;

INSERT INTO job_services (id, categoria, titulo, descripcion, creador_id, form_schema) VALUES
 ('11111111-0000-0000-0000-000000000001','cleaning','Limpieza profunda del hogar','Cocina, baños, habitaciones y zonas comunes. Incluye desinfección de superficies.','99999999-0000-0000-0000-000000000001','{}'),
 ('11111111-0000-0000-0000-000000000002','cleaning','Limpieza después de mudanza','Dejamos tu apartamento listo para entregar o habitar: pisos, ventanas y clósets.','99999999-0000-0000-0000-000000000001','{}'),
 ('11111111-0000-0000-0000-000000000003','plumbing','Reparación de fugas','Detección y arreglo de fugas en lavaplatos, sanitarios, duchas y tuberías expuestas.','99999999-0000-0000-0000-000000000001','{}'),
 ('11111111-0000-0000-0000-000000000004','plumbing','Instalación de calentador','Instalación de calentadores de paso o de acumulación, a gas o eléctricos.','99999999-0000-0000-0000-000000000001','{}'),
 ('11111111-0000-0000-0000-000000000005','electrical','Instalación de lámparas','Montaje de lámparas de techo y pared, con revisión del circuito.','99999999-0000-0000-0000-000000000001','{}'),
 ('11111111-0000-0000-0000-000000000006','electrical','Revisión de tablero eléctrico','Diagnóstico de breakers, cortos y sobrecargas en el tablero de la vivienda.','99999999-0000-0000-0000-000000000001','{}'),
 ('11111111-0000-0000-0000-000000000007','painting','Pintura de interiores','Pintura de paredes y techos con preparación de superficie y resanes.','99999999-0000-0000-0000-000000000001','{}'),
 ('11111111-0000-0000-0000-000000000008','gardening','Mantenimiento de jardín','Poda, corte de césped y limpieza de matas en jardines y terrazas.','99999999-0000-0000-0000-000000000001','{}');

INSERT INTO job_service_offers (id, job_service_id, offerant_id, tipo_tarifa, valor, zona, estado) VALUES
 ('22222222-0000-0000-0000-000000000001','11111111-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','fijo',120000,'Chapinero','activo'),
 ('22222222-0000-0000-0000-000000000002','11111111-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000002','hora',28000,'Usaquén','activo'),
 ('22222222-0000-0000-0000-000000000003','11111111-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000003','fijo',150000,NULL,'activo'),
 ('22222222-0000-0000-0000-000000000004','11111111-0000-0000-0000-000000000002','aaaaaaaa-0000-0000-0000-000000000001','fijo',220000,'Chapinero','activo'),
 ('22222222-0000-0000-0000-000000000005','11111111-0000-0000-0000-000000000003','aaaaaaaa-0000-0000-0000-000000000004','hora',45000,'Teusaquillo','activo'),
 ('22222222-0000-0000-0000-000000000006','11111111-0000-0000-0000-000000000003','aaaaaaaa-0000-0000-0000-000000000005','fijo',90000,'Suba','activo'),
 ('22222222-0000-0000-0000-000000000007','11111111-0000-0000-0000-000000000004','aaaaaaaa-0000-0000-0000-000000000004','fijo',180000,'Teusaquillo','activo'),
 ('22222222-0000-0000-0000-000000000008','11111111-0000-0000-0000-000000000005','aaaaaaaa-0000-0000-0000-000000000006','fijo',60000,'Kennedy','activo'),
 ('22222222-0000-0000-0000-000000000009','11111111-0000-0000-0000-000000000006','aaaaaaaa-0000-0000-0000-000000000006','hora',50000,'Kennedy','activo'),
 ('22222222-0000-0000-0000-000000000010','11111111-0000-0000-0000-000000000007','aaaaaaaa-0000-0000-0000-000000000007','hora',38000,'Engativá','activo'),
 ('22222222-0000-0000-0000-000000000011','11111111-0000-0000-0000-000000000007','aaaaaaaa-0000-0000-0000-000000000008','fijo',450000,'Chapinero','pausado'),
 ('22222222-0000-0000-0000-000000000012','11111111-0000-0000-0000-000000000008','aaaaaaaa-0000-0000-0000-000000000009','hora',32000,'Usaquén','activo');
COMMIT;
