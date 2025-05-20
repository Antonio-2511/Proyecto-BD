-- Clientes que han gastado más que la media general de clientes

select c.Nombre,sum(p2.Importe)
from Cliente c 
join Pedido p 
on c.DNI_Cliente =p.Cliente_DNI_Cliente 
join Pago p2 
on p.idPedido =p2.Pedido_idPedido 
group by c.Nombre 
having  sum(p2.Importe ) > 
(select avg(total_cliente) 
from(
select sum(p2.Importe)as total_cliente
from Cliente c
join Pedido p 
on c.DNI_Cliente =p.Cliente_DNI_Cliente 
join Pago p2 
on p.idPedido =p2.Pedido_idPedido
group by c.Nombre )as sub);


-- El producto más vendido por cada local

SELECT l.Ciudad ,p2.Descripcion,sum(pdp.cantidad) as cantidad_vendida  
from Local l 
join Pedido p 
on l.idLocal =p.Local_idLocal 
join Productos_del_pedido pdp 
on p.idPedido =pdp.Pedido_idPedido 
join Producto p2 
on pdp.Producto_idProducto =p2.idProducto 
group by idLocal,p2.idProducto  
order BY l.Ciudad, cantidad_vendida DESC;


-- "Mostrar por cada cliente el total gastado, el número de 
-- pedidos y el promedio gastado por pedido, pero solo si ha 
-- hecho al menos 2 pedidos."

select c.Nombre,sum(p2.Importe )as total_gastado,COUNT(p.idPedido ) as total_pedidos, 
avg(p2.Importe ) as promedio_por_pedido 
from Cliente c 
JOIN Pedido p 
on c.DNI_Cliente =p.Cliente_DNI_Cliente 
join Pago p2
on p.idPedido =p2.Pedido_idPedido 
group by c.Nombre 
having count(p.idPedido) >= 2 ;





-- Mostrar los empleados que han gestionado pedidos con un importe total 
-- superior al importe medio de todos los empleados

select e.Nombre,sum(p2.Importe) as total_facturado,
count(p.idPedido) as total_pedidos
from Empleado e
join Pedido p 
on e.idEmpleado = p.Empleado_idEmpleado
join Pago p2 
on p.idPedido = p2.Pedido_idPedido
group by e.idEmpleado
having sum(p2.Importe) > (
    select avg(sub.total_empleado)
    from (
        select sum(p4.Importe) as total_empleado
        from Empleado e2
        join Pedido p3 
        on e2.idEmpleado = p3.Empleado_idEmpleado
        join Pago p4 
        on p3.idPedido = p4.Pedido_idPedido
        group by e2.idEmpleado)as sub);





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


-- Productos vendidos con su total de ingresos generados y el 
-- total de pedidos distintos en los que ha estado

create view vista_productos_ingresos as
SELECT p.idProducto,sum(pdp.Cantidad)as total_productos_vendidos,
sum(p.idProducto*pdp.Cantidad)as total_facturado,
count(DISTINCT pdp.Pedido_idPedido)as productos_en_pedidos_dif
from Producto p 
join Productos_del_pedido pdp 
on p.idProducto =pdp.Producto_idProducto 
group by p.idProducto;





-- Crear una función que reciba el DNI de un cliente y devuelva 
-- cuántos productos diferentes ha comprado en total 
-- (aunque haya hecho varios pedidos).

DELIMITER $$
CREATE FUNCTION contar_productos_diferentes_cliente(dni_Cliente VARCHAR(45))
RETURNS INT
DETERMINISTIC
BEGIN
   DECLARE salida INT DEFAULT 0;
select count(DISTINCT p2.idProducto ) into salida
from Cliente c 
join Pedido p 
on c.DNI_Cliente =p.Cliente_DNI_Cliente
join Productos_del_pedido pdp 
on p.idPedido =pdp.Pedido_idPedido 
join Producto p2 
on pdp.Producto_idProducto =p2.idProducto 
where c.DNI_Cliente =dni_Cliente;

return salida;

END $$
DELIMITER ;

select contar_productos_diferentes_cliente('01859420I');



-- función que reciba el DNI de un cliente y devuelva el porcentaje de 
-- pedidos que ha realizado respecto al total de pedidos en el sistema.



DELIMITER $$
CREATE FUNCTION porcentaje_pedidos_cliente(dni_Cliente VARCHAR(45))
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
	
   DECLARE pedidos_clientes INT DEFAULT 0;
   DECLARE pedidos_totales int default 0;
   DECLARE porcentaje DECIMAL(7,2) DEFAULT 0;

SELECT count(*) into pedidos_clientes
FROM Cliente c 
join Pedido p 
on c.DNI_Cliente =p.Cliente_DNI_Cliente
WHERE c.DNI_Cliente = dni_Cliente;

select count(*) into pedidos_totales
from Pedido p ;

SET porcentaje = (pedidos_clientes * 100.0) / pedidos_totales;

return porcentaje;

END $$
DELIMITER ;

select porcentaje_pedidos_cliente('27009521H');






-- procedimiento que muestre los 5 productos con más unidades vendidas 
-- en el último mes

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
  set stock = stock + OLD.Cantidad
  where idProducto = OLD.Producto_idProducto;
end $$

DELIMITER ;

select idProducto, stock from Producto where idProducto = 1;

delete from Productos_del_pedido 
where Pedido_idPedido = 10 and Producto_idProducto = 1;

select idProducto, stock from Producto where idProducto = 1;

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

insert into Pago (idPago, Pedido_idPedido, Fecha_Pago, Importe)
values (1002, 10, curdate(), 100.00);

