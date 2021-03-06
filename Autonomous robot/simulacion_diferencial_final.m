clear all
clc

%joy = vrjoystick(1);

global l
global radio_rueda
global camino
global pose
global pose2
global punto


l=3.5; %semidistancia entre rudas delanteras y traseras, tambien definido en modelo
radio_rueda=1;

%Carga el fichero  BMP
MAPA = imread('restaurante2.bmp');

%Transformación para colocar correctamente el origen del Sistema de
%Referencia
MAPA(1:end,:,:)=MAPA(end:-1:1,:,:);

%Tamaño de las celdas del grid
delta=15;
%genera la ruta óptima
Optimal_path=A_estrella(MAPA, delta);

%Condiciones iniciales 
pose0=[Optimal_path(1,1); Optimal_path(1,2); pi/2];
posef=[Optimal_path(end,1); Optimal_path(end,2); 3*pi/2];

%definir camino
dd=5;
da=dd;

posicion_despegue=[41 540];
posicion_aterriza=[posef(1)-(da*cos(posef(3))) posef(2)-(da*sin(posef(3)))];

xc=[pose0(1) posicion_despegue(1) Optimal_path(2:end-1,1)' posicion_aterriza(1) posef(1)];
yc=[pose0(2) posicion_despegue(2) Optimal_path(2:end-1,2)' posicion_aterriza(2) posef(2)];

ds=1; %distancia entre puntos en cm.
camino=funcion_spline_cubica_varios_puntos(xc,yc,ds)';

%--------------------------------------------------------------------------------------------------
t0=0;

%final de la simulación
tf=100;

%paso de integracion
h=0.1;
%vector tiempo
t=0:h:tf;
%indice de la matriz
k=0;

%inicialización valores iniciales
pose(:,k+1)=pose0;

t(k+1)=t0;

while (t0+h*k) < tf,
    
    %actualización
    k=k+1;
 
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%punto más cercano
	orden_minimo= minima_distancia(camino, pose(1:2,k));

	Look_ahead=20;
	seguir=orden_minimo+Look_ahead;
	if(orden_minimo+Look_ahead>length(camino))
		seguir=length(camino);
	end
	punto=[camino(seguir,1), camino(seguir, 2)];

    delta = (pose(1,k)-punto(1))*sin(pose(3,k))-(pose(2,k)-punto(2))*cos(pose(3,k));
    LH=sqrt((pose(1,k)-punto(1))^2 + (pose(2,k)-punto(2))^2);
    rho=2*delta/LH^2;
    
    Distancia_al_final=sqrt((pose(1,k)-camino(end,1))^2 + (pose(2,k)-camino(end,2))^2);
    
    V0=1*LH;
    if(V0>50)
        V0=50;
    end
    
    W=V0*rho;
    velocidad_derecha=(1/radio_rueda)*(V0+W*l);
    velocidad_izquierda=(1/radio_rueda)*(V0-W*l);
    
    conduccion=[velocidad_derecha velocidad_izquierda];
    
	%metodo de integración ruge-kuta
	pose(:,k+1)=kuta_diferencial_mapa(t(k),pose(:,k),h,conduccion,MAPA);

end

%PROGRAMACIÓN EL VOLVER HACIA ATRÁS
%Con la función flip, podemos hacer que invierta la matriz y por tanto
%recorra el camino hacia atrás
camino = flip(camino);

%Ahora pose0, tendrá como posición inicial, los valores de posef del
%anterior bucle
pose0=[posef(1); posef(2); posef(3)];

%final de la simulación -- amplio tanto tiempo en caso de que se elija el camino más largo
tf=tf+150;

%vector tiempo
t=0:h:tf;

%inicialización valores iniciales
pose(:,k+1)=pose0;

t(k+1)=t0;

while (t0+h*k) < tf,
    
    %actualización
    k=k+1;
 
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%punto más cercano
	orden_minimo= minima_distancia(camino, pose(1:2,k));

	Look_ahead=20;
	seguir=orden_minimo+Look_ahead;
	if(orden_minimo+Look_ahead>length(camino))
		seguir=length(camino);
	end
	punto=[camino(seguir,1), camino(seguir, 2)];

    delta = (pose(1,k)-punto(1))*sin(pose(3,k))-(pose(2,k)-punto(2))*cos(pose(3,k));
    LH=sqrt((pose(1,k)-punto(1))^2 + (pose(2,k)-punto(2))^2);
    rho=2*delta/LH^2;
    
    Distancia_al_final=sqrt((pose(1,k)-camino(end,1))^2 + (pose(2,k)-camino(end,2))^2);
    
    V0=1*LH;
    if(V0>50)
        V0=50;
    end
    
    W=V0*rho;
    velocidad_derecha=(1/radio_rueda)*(V0+W*l);
    velocidad_izquierda=(1/radio_rueda)*(V0-W*l);
    
	%velocidad con signo negativo para que vaya hacia atrás
    conduccion=[-velocidad_derecha -velocidad_izquierda];
    
	%metodo de integración ruge-kuta
	pose(:,k+1)=kuta_diferencial_mapa(t(k),pose(:,k),h,conduccion,MAPA);

end