clearvars
clc
close all

%% =========================================
% CONFIGURACION DEL PUERTO SERIAL
% =========================================

disp('Puertos disponibles:');
disp(serialportlist("available")')

disp('Arduino debe estar conectado sin Serial Monitor ni Serial Plot');

port = "COM4";
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

% Valores de entrada que se probaran
U_values = linspace(-1.5, 1.5, 150);

% Tiempo que se mantiene cada entrada
tiempoEspera = 3;       % segundos

% Frecuencia de muestreo
frecuencia = 20;        % muestras/segundo
dt = 1/frecuencia;

% Numero de muestras por escalon
NumSamples = tiempoEspera * frecuencia;

% Reservar memoria para el valor final
W_final = zeros(size(U_values));

%% =========================================
% EXPERIMENTO
% =========================================

disp(' ');
disp('=========================================');
disp('INICIANDO IDENTIFICACION EN ESTADO ESTACIONARIO');
disp('=========================================');

for i = 1:length(U_values)

    % Entrada actual
    U_actual = U_values(i);

    fprintf('\nAplicando U = %.2f\n', U_actual);

    % Vector para almacenar las mediciones
    W = zeros(1, NumSamples);

    tic;

    for k = 1:NumSamples

        % Enviar entrada
        writeline(pserial, num2str(U_actual));

        % Leer salida
        strResponse = readline(pserial);
        W(k) = str2double(strResponse);

        % Esperar entre muestras
        pause(dt);

    end

    % -----------------------------------------
    % Valor final = promedio de las ultimas
    % mediciones
    % -----------------------------------------

    numFinales = round(0.5 * frecuencia);

    W_final(i) = mean(W(end-numFinales+1:end));

    fprintf('W(inf) = %.4f\n', W_final(i));

end

%% =========================================
% REGRESAR ENTRADA A CERO
% =========================================

writeline(pserial, num2str(0));

disp(' ');
disp('Experimento terminado.');
disp('Entrada regresada a cero.');

%% =========================================
% MOSTRAR RESULTADOS
% =========================================

disp(' ');
disp('=========================================');
disp('RESULTADOS');
disp('=========================================');

for i = 1:length(U_values)
    fprintf('U = %6.2f    W(inf) = %8.4f\n', ...
        U_values(i), W_final(i));
end

%% =========================================
% GRAFICA DE LA CARACTERISTICA ESTATICA
% =========================================

figure('Name','Caracteristica estatica del sistema');

plot(U_values, W_final, 'o-', ...
    'LineWidth', 1.8, ...
    'MarkerSize', 6);

grid on;

xlabel('U (entrada)');
ylabel('W(\infty) (salida final)');

title('Caracteristica estatica entrada-salida');

xlim([min(U_values) max(U_values)]);

%% =========================================
% AJUSTE SUAVE PARA VISUALIZACION
% =========================================

hold on;

U_suave = linspace(min(U_values), max(U_values), 300);

W_suave = interp1(U_values, W_final, U_suave, 'pchip');

plot(U_suave, W_suave, 'LineWidth', 2);

legend('Datos experimentales','Curva característica', ...
       'Location','best');

hold off;
