-- 1. Consulta de una tabla con WHERE
SELECT * 
FROM Producto
WHERE Precio > 100;

-- 2. Consulta de más de una tabla (con LEFT JOIN)
SELECT Pedido.idPedido, Cliente.Nombre AS Nombre_Cliente, Empleado.Nombre AS Nombre_Empleado
FROM Pedido
LEFT JOIN Cliente ON Pedido.Cliente_DNI_Cliente = Cliente.DNI_Cliente
LEFT JOIN Empleado ON Pedido.Empleado_idEmpleado = Empleado.idEmpleado;

-- 3. Consulta con agrupación (con LEFT JOIN)
SELECT Pedido.idPedido, SUM(Productos_del_pedido.Cantidad) AS Total_Productos_Vendidos
FROM Pedido
LEFT JOIN Productos_del_pedido ON Pedido.idPedido = Productos_del_pedido.Pedido_idPedido
GROUP BY Pedido.idPedido;

-- 4. Consulta con subconsultas (sin JOIN)
SELECT * 
FROM Producto
WHERE Precio > (SELECT AVG(Precio) FROM Producto);

-- 5. Consulta que combine varias anteriores (con LEFT JOIN)
SELECT Pedido.idPedido, Cliente.Nombre AS Nombre_Cliente, 
       SUM(Productos_del_pedido.Cantidad) AS Total_Productos_Vendidos
FROM Pedido
LEFT JOIN Cliente ON Pedido.Cliente_DNI_Cliente = Cliente.DNI_Cliente
LEFT JOIN Productos_del_pedido ON Pedido.idPedido = Productos_del_pedido.Pedido_idPedido
GROUP BY Pedido.idPedido
HAVING Total_Productos_Vendidos > 10;

-- 1. Función: Contar los productos de una categoría
DELIMITER &&
DROP FUNCTION IF EXISTS contar_productos_categoria &&
CREATE FUNCTION contar_productos_categoria(categoria VARCHAR(50))
  RETURNS INT UNSIGNED
BEGIN
  DECLARE total INT UNSIGNED;
  SET total = (
    SELECT COUNT(*) 
    FROM Producto
    WHERE Producto.tipo = categoria);
  RETURN total;
END &&
DELIMITER ;

-- 2. Función: Obtener el precio promedio de todos los productos
DELIMITER &&
DROP FUNCTION IF EXISTS obtener_precio_promedio &&
CREATE FUNCTION obtener_precio_promedio()
  RETURNS DECIMAL(15,2)
BEGIN
  DECLARE promedio DECIMAL(15,2);
  SET promedio = (
    SELECT AVG(Precio)
    FROM Producto);
  RETURN promedio;
END &&
DELIMITER ;

-- 1. Procedimiento: Actualizar el precio de un producto
DELIMITER &&
DROP PROCEDURE IF EXISTS actualizar_precio_producto &&
CREATE PROCEDURE actualizar_precio_producto(id_producto INT, nuevo_precio DECIMAL(15,2))
BEGIN
  UPDATE Producto 
  SET Precio = nuevo_precio
  WHERE idProducto = id_producto;
END &&
DELIMITER ;

-- 2. Procedimiento: Registrar un nuevo cliente
DELIMITER &&
DROP PROCEDURE IF EXISTS registrar_cliente &&
CREATE PROCEDURE registrar_cliente(DNI_Cliente VARCHAR(45), Nombre VARCHAR(45), Apellidos VARCHAR(45), Telefono FLOAT)
BEGIN
  INSERT INTO Cliente (DNI_Cliente, Nombre, Apellidos, Telefono)
  VALUES (DNI_Cliente, Nombre, Apellidos, Telefono);
END &&
DELIMITER ;

-- 3. Procedimiento: Eliminar un pedido por ID
DELIMITER &&
DROP PROCEDURE IF EXISTS eliminar_pedido &&
CREATE PROCEDURE eliminar_pedido(id_pedido INT)
BEGIN
  DELETE FROM Pedido WHERE idPedido = id_pedido;
END &&
DELIMITER ;

-- 1. Trigger: Actualizar el stock cuando se agrega un artículo a un pedido
DELIMITER &&
DROP TRIGGER IF EXISTS actualizar_stock &&
CREATE TRIGGER actualizar_stock_after_insert
AFTER INSERT
ON Productos_del_pedido FOR EACH ROW
BEGIN
  UPDATE Producto 
  SET stock = stock - NEW.Cantidad
  WHERE idProducto = NEW.Producto_idProducto;
END &&
DELIMITER ;

-- 2. Trigger: Actualizar fecha de modificacion al cambiar algo en un pedido

DELIMITER &&
DROP TRIGGER IF EXISTS trigger_actualizar_pedido &&
CREATE TRIGGER trigger_actualizar_pedido
BEFORE UPDATE
ON Pedido FOR EACH ROW
BEGIN
  SET NEW.Fecha_Modificacion = NOW();
END &&

DELIMITER ;

