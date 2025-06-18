-- 1. Clientes que han gastado más que la media general de clientes

SELECT c.Nombre, sum(p2.Importe) as total_gastado
FROM Cliente c 
JOIN Pedido p 
ON c.DNI_Cliente = p.Cliente_DNI_Cliente 
JOIN Pago p2 
ON p.idPedido = p2.Pedido_idPedido 
GROUP BY c.Nombre
HAVING sum(p2.Importe) > (
SELECT avg(cliente_total)
FROM (
SELECT sum(p2.Importe) as cliente_total
FROM Cliente c
JOIN Pedido p 
on c.DNI_Cliente = p.Cliente_DNI_Cliente 
JOIN Pago p2 
on p.idPedido = p2.Pedido_idPedido
GROUP BY c.DNI_Cliente) as sub
);












select l.idLocal,l.Ciudad,sum(pdp.Cantidad) as total_vendidos
from Local l
join Pedido p 
on l.idLocal = p.Local_idLocal
join Productos_del_pedido pdp 
on p.idPedido = pdp.Pedido_idPedido
join Producto pr 
on pdp.Producto_idProducto = pr.idProducto
where pr.Marca = 'Apple' and l.Ciudad = 'Madrid'
group by l.idLocal
order by total_vendidos desc
limit 5;









-- Clientes que han comprado más de 3 productos distintos y han gastado más de 250€


select c.Nombre,count(distinct pdp.Producto_idProducto) as productos_distintos,
sum(pg.Importe) as total_gastado
from Cliente c
join Pedido p 
on c.DNI_Cliente = p.Cliente_DNI_Cliente
join Productos_del_pedido pdp 
on p.idPedido = pdp.Pedido_idPedido
join Pago pg 
on p.idPedido = pg.Pedido_idPedido
group by c.DNI_Cliente
having productos_distintos > 3 and total_gastado > 250;






-- Mostrar los clientes nacidos después del 2000 que han comprado productos de todas las marcas 


select c.Nombre,count(distinct pr.Marca) as marcas_compradas
from Cliente c
join Pedido p 
on c.DNI_Cliente = p.Cliente_DNI_Cliente
join Productos_del_pedido pdp 
on p.idPedido = pdp.Pedido_idPedido
join Producto pr 
on pdp.Producto_idProducto = pr.idProducto
where c.Fecha_nacimiento > '2000-01-01'
group by c.DNI_Cliente
having marcas_compradas = 5;











-- Mostrar los productos cuya cantidad total vendida supera 
-- el promedio de cantidad vendida entre todos los productos.


select p.idProducto,sum(pdp.Cantidad)as total
from Producto p 
join Productos_del_pedido pdp 
ON p.idProducto =pdp.Producto_idProducto 
group by p.idProducto 
having total > (
SELECT avg(sub.total_cantidad) 
from (
select sum(pdp2.Cantidad) as total_cantidad  
from Producto p2
join Productos_del_pedido pdp2 
ON p2.idProducto =pdp2.Producto_idProducto 
group by p2.idProducto )
as sub);







-- Crear una vista que muestre solo los clientes que han hecho 
-- al menos 3 pedidos, han gastado más de 500 € en total,e 
-- incluya: su DNI, nombre, número de pedidos y total gastado.


create view vista_clientes_frecuentes as
select c.DNI_Cliente,c.Nombre,count(p.idPedido)as total_pedidos,
sum(pdp.cantidad*p.idPedido)as total_gastado
from Cliente c
join Pedido p
on c.DNI_Cliente=p.Cliente_DNI_Cliente
join Productos_del_pedido pdp
on p.idPedido=pdp.Pedido_idPedido
group by c.DNI_Cliente
having total_pedidos >= 3
AND total_gastado > 500;








-- Vista que muestra, por cada empleado, su nombre completo, la ciudad donde trabaja,
-- la cantidad de pedidos que ha gestionado, el importe total facturado en esos pedidos,
-- y el importe promedio facturado por pedido.

create view vista_empleados_rendimiento as
select e.idEmpleado,concat(e.Nombre, ' ', e.Apellidos) as nombre_completo,
l.Ciudad,count(distinct p.idPedido) as pedidos_gestionados,
sum(pg.Importe) as total_facturado,
avg(pg.Importe) as promedio_por_pedido
from Empleado e
join Local l 
on e.Local_idLocal = l.idLocal
join Pedido p 
on e.idEmpleado = p.Empleado_idEmpleado
join Pago pg 
on p.idPedido = pg.Pedido_idPedido
group by e.idEmpleado;












-- Crear una función que reciba el DNI de un cliente y devuelva 
-- cuántos productos diferentes ha comprado en total, y devolver -1 si 
-- el cliente no existe

DELIMITER $$
CREATE FUNCTION contar_productos_diferentes_cliente(dni_Cliente VARCHAR(45))
RETURNS INT
DETERMINISTIC
BEGIN
   DECLARE salida INT DEFAULT 0;

   if not exists (select 1 from Cliente where DNI_Cliente = dni_Cliente) then
      return -1;
   end if;

   select count(distinct p2.idProducto) into salida
   from Cliente c 
   join Pedido p on c.DNI_Cliente = p.Cliente_DNI_Cliente
   join Productos_del_pedido pdp on p.idPedido = pdp.Pedido_idPedido 
   join Producto p2 on pdp.Producto_idProducto = p2.idProducto 
   where c.DNI_Cliente = dni_Cliente;

   return salida;
END $$
DELIMITER ;


select contar_productos_diferentes_cliente('01859420I');











-- Función que reciba el DNI de un cliente y devuelva el porcentaje de 
-- pedidos que ha realizado respecto al total de pedidos en el sistema, 
-- y devolver -1 si el cliente no existe

DELIMITER $$
CREATE FUNCTION porcentaje_pedidos_cliente(dni_Cliente VARCHAR(45))
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
   DECLARE pedidos_clientes INT DEFAULT 0;
   DECLARE pedidos_totales INT DEFAULT 0;
   DECLARE porcentaje DECIMAL(7,2) DEFAULT 0;

   if not exists (select 1 from Cliente where DNI_Cliente = dni_Cliente) then
      return -1;
   end if;

   select count(*) into pedidos_clientes
   from Pedido
   where Cliente_DNI_Cliente = dni_Cliente;

   select count(*) into pedidos_totales
   from Pedido;

   if pedidos_totales = 0 then
      return null;
   end if;
   set porcentaje = (pedidos_clientes * 100.0) / pedidos_totales;

   return porcentaje;
END $$
DELIMITER ;

select porcentaje_pedidos_cliente('27009521H');










-- Procedimiento que muestra los 5 productos con más unidades vendidas 
-- entre dos fechas dadas como parámetros (fecha_inicio y fecha_fin),
-- ordenados por cantidad total vendida en ese periodo.


DELIMITER $$

CREATE PROCEDURE top_5_productos_vendidos_mes (IN fecha_inicio DATE,
IN fecha_fin DATE)
BEGIN
    SELECT p.idProducto,p.Descripcion,sum(pdp.Cantidad) as total_vendido,
count(DISTINCT pdp.Pedido_idPedido) as num_pedidos
FROM Producto p
JOIN Productos_del_pedido pdp 
on p.idProducto = pdp.Producto_idProducto
join Pedido pe 
on pdp.Pedido_idPedido = pe.idPedido
WHERE pe.Fecha_Pedido BETWEEN fecha_inicio AND fecha_fin
GROUP BY p.idProducto, p.Descripcion
ORDER BY total_vendido DESC
LIMIT 5;
    
END $$

DELIMITER ;

CALL top_5_productos_vendidos_mes('2025-01-01', '2025-12-31');



-- procedimiento para ver Clientes que han comprado 2 o más 
-- productos diferentes de la misma marca


DELIMITER $$

CREATE PROCEDURE clientes_fieles_a_marca()
BEGIN
    SELECT c.DNI_Cliente,c.Nombre,p2.Marca,
count(DISTINCT p2.idProducto) as productos_distintos
FROM Cliente c
JOIN Pedido p 
on c.DNI_Cliente = p.Cliente_DNI_Cliente
JOIN Productos_del_pedido pdp 
on p.idPedido = pdp.Pedido_idPedido
JOIN Producto p2 
on pdp.Producto_idProducto = p2.idProducto
GROUP BY c.DNI_Cliente, c.Nombre, p2.Marca
HAVING COUNT(DISTINCT p2.idProducto) >= 2
ORDER BY c.Nombre, p2.Marca;
END $$

DELIMITER ;

CALL clientes_fieles_a_marca();



-- Procedimiento para ver el numero de pedido, la fecha y el cliente 
-- al que ha atendido un empleado 


DELIMITER $$

create procedure pedidos_por_empleado (in p_id_empleado varchar(45)
)
begin
select p.Num_Pedido,p.Fecha_Pedido,c.Nombre as cliente
from Pedido p
join Cliente c 
on p.Cliente_DNI_Cliente = c.DNI_Cliente
join Pago p2 
on p.idPedido = p2.Pedido_idPedido
where p.Empleado_idEmpleado = p_id_empleado
group by p.idPedido, p.Num_Pedido, p.Fecha_Pedido, c.Nombre
order by p.Fecha_Pedido desc;
end $$

DELIMITER ;

call pedidos_por_empleado('E0009');





-- Trigger para actualizar stock al original si se cancela un pedido

DELIMITER $$

create trigger devolver_stock_al_eliminar
after delete on Productos_del_pedido
for each row
begin
  update Producto
  set stock = stock + old.Cantidad
  where idProducto = old.Producto_idProducto;
end $$

DELIMITER ;

select idProducto, stock 
from Producto 
where idProducto = 1;

delete from Productos_del_pedido 
where Pedido_idPedido = 10 and Producto_idProducto = 1;


select idProducto, stock 
from Producto 
where idProducto = 1;


















-- Trigger para impedir que se inserte un pago con importe negativo o mayor al total del pedido

DELIMITER $$

create trigger validar_pago
before insert on Pago
for each row
begin
  declare total_permitido decimal(10,2);
  declare mensaje_error varchar(255);

  select sum(pdp.Cantidad * pr.Precio)
  into total_permitido
  from Productos_del_pedido pdp
  join Producto pr on pdp.Producto_idProducto = pr.idProducto
  where pdp.Pedido_idPedido = NEW.Pedido_idPedido;

  if NEW.Importe < 0 then
    signal sqlstate '45000'
    set message_text = 'El importe no puede ser negativo.';
  end if;

  if NEW.Importe > total_permitido then
    set mensaje_error = concat('El importe no puede superar el total del pedido: ', total_permitido);
    signal sqlstate '45000'
    set message_text = mensaje_error;
  end if;
end $$

DELIMITER ;

insert into Pago (idPago, Fecha_Pago, Metodo_pago, Importe, Pedido_idPedido)
values (1005, curdate(), 'Tarjeta', 1800.00, 10);
