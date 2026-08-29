clearvars
clc
close all

%% =========================================
% CONFIGURACION DEL PUERTO SERIAL
% =========================================
disp('Puertos disponibles:');
disp(serialportlist("available")')
disp('Arduino debe estar conectado sin Serial Monitor ni Serial Plot');
port = "/dev/cu.usbserial-10";
baudRate = 115200;
pserial = serialport(port, baudRate);
pserial.Timeout = 2;
configureTerminator(pserial, "CR/LF");
flush(pserial);
disp('Esperando a que Arduino este listo...');
pause(2);

%% =========================================
% PARAMETROS DEL EXPERIMENTO
% =========================================
numPuntos = 150;

% Vectores de entrada: Ascendente y Descendente
U_up   = linspace(-1.5, 1.5, numPuntos);
U_down = linspace(1.5, -1.5, numPuntos);

% Tiempo que se mantiene cada entrada
tiempoEspera = 3;       % segundos
frecuencia   = 20;      % muestras/segundo
dt = 1 / frecuencia;
NumSamples   = tiempoEspera * frecuencia;
numFinales   = round(0.5 * frecuencia);

% Reservar memoria para los resultados
W_final_up   = zeros(size(U_up));
W_final_down = zeros(size(U_down));

%% =========================================
% PRUEBA 1: BARRIDO ASCENDENTE (-1.5 a 1.5)
% =========================================
disp(' ');
disp('=========================================');
disp('INICIANDO PRUEBA 1: BARRIDO ASCENDENTE (-1.5 -> 1.5)');
disp('=========================================');

for i = 1:length(U_up)
    U_actual = U_up(i);
    fprintf('Ascendente [%d/%d] | U = %6.2f', i, numPuntos, U_actual);
    
    W = zeros(1, NumSamples);
    for k = 1:NumSamples
        writeline(pserial, num2str(U_actual));
        strResponse = readline(pserial);
        W(k) = str2double(strResponse);
        pause(dt);
    end
    
    W_final_up(i) = mean(W(end-numFinales+1:end));
    fprintf('  -->  W(inf) = %8.4f\n', W_final_up(i));
end

%% =========================================
% PRUEBA 2: BARRIDO DESCENDENTE (1.5 a -1.5)
% =========================================
disp(' ');
disp('=========================================');
disp('INICIANDO PRUEBA 2: BARRIDO DESCENDENTE (1.5 -> -1.5)');
disp('=========================================');

for i = 1:length(U_down)
    U_actual = U_down(i);
    fprintf('Descendente [%d/%d] | U = %6.2f', i, numPuntos, U_actual);
    
    W = zeros(1, NumSamples);
    for k = 1:NumSamples
        writeline(pserial, num2str(U_actual));
        strResponse = readline(pserial);
        W(k) = str2double(strResponse);
        pause(dt);
    end
    
    W_final_down(i) = mean(W(end-numFinales+1:end));
    fprintf('  -->  W(inf) = %8.4f\n', W_final_down(i));
end

%% =========================================
% REGRESAR ENTRADA A CERO
% =========================================
writeline(pserial, num2str(0));
disp(' ');
disp('Experimento completado.');
disp('Entrada regresada a cero de forma segura.');

%% =========================================
% GRAFICA CON AREA DE HISTÉRESIS COLOREADA
% =========================================
figure('Name', 'Caracteristica Estatica: Histeresis y Zona Muerta', 'Color', 'w');
hold on;

% 1. Relleno poligonal entre las dos curvas (Histéresis)
% Como U_up va de -1.5 a 1.5 y U_down de 1.5 a -1.5, [U_up, U_down] cierra el polígono
x_fill = [U_up, U_down];
y_fill = [W_final_up, W_final_down];

fill(x_fill, y_fill, [0.93, 0.69, 0.13], ... % Color amarillo/dorado traslúcido
    'FaceAlpha', 0.25, ...                   % 25% de opacidad para ver el fondo
    'EdgeColor', 'none', ...
    'DisplayName', 'Área de Histéresis');

% 2. Curva del Barrido Ascendente (-1.5 a 1.5) en Azul
plot(U_up, W_final_up, 'o-', ...
    'Color', [0, 0.4470, 0.7410], ...
    'LineWidth', 1.8, ...
    'MarkerSize', 5, ...
    'MarkerFaceColor', [0, 0.4470, 0.7410], ...
    'DisplayName', 'Barrido Ascendente (-1.5 \rightarrow 1.5)');

% 3. Curva del Barrido Descendente (1.5 a -1.5) en Naranja/Rojo
plot(U_down, W_final_down, 's-', ...
    'Color', [0.8500, 0.3250, 0.0980], ...
    'LineWidth', 1.8, ...
    'MarkerSize', 5, ...
    'MarkerFaceColor', [0.8500, 0.3250, 0.0980], ...
    'DisplayName', 'Barrido Descendente (1.5 \rightarrow -1.5)');

% Ajustes visuales de la figura
grid on;
box on;
xlabel('Entrada U', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Salida en Estado Estacionario W(\infty)', 'FontSize', 11, 'FontWeight', 'bold');
title('Característica Estática con Región de Histéresis', 'FontSize', 12);
legend('Location', 'northwest', 'FontSize', 10);
xlim([-1.6 1.6]);
hold off;
