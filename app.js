class NetworkManager {
    constructor() {
        this.activeConnections = 0;
        this.queueLength = 0;
        this.transferRate = 0;
        
        Socket.init();
        PacketVisualizer.init();
        EventLogger.init();
        
        this.bindEvents();
        this.updateStats();
    }

    bindEvents() {
        document.getElementById('startServer').addEventListener('click', () => this.startServer());
        document.getElementById('stopServer').addEventListener('click', () => this.stopServer());
        document.getElementById('connectClient').addEventListener('click', () => this.connectClient());
        document.getElementById('disconnectClient').addEventListener('click', () => this.disconnectClient());
        document.getElementById('sendLoad').addEventListener('click', () => this.sendLoad());
        document.getElementById('aiOptimize').addEventListener('click', () => this.aiOptimize());
        document.getElementById('executeAttack').addEventListener('click', () => this.executeAttack());
        document.getElementById('applyDefense').addEventListener('click', () => this.applyDefense());
        document.getElementById('enableTimestamps').addEventListener('click', () => this.toggleTimestamps());
        document.getElementById('enableNonRepudiation').addEventListener('click', () => this.toggleNonRepudiation());
        document.getElementById('enableHSM').addEventListener('click', () => this.toggleHSM());
    }

    updateStats() {
        document.getElementById('activeConnections').textContent = this.activeConnections;
        document.getElementById('queueLength').textContent = this.queueLength;
        document.getElementById('transferRate').textContent = this.transferRate.toFixed(1);
    }

    startServer() {
        Socket.start();
        document.getElementById('startServer').disabled = true;
        document.getElementById('stopServer').disabled = false;
        document.getElementById('connectClient').disabled = false;
        document.getElementById('statusDot').classList.add('active');
        document.getElementById('statusText').textContent = 'Servidor activo - Esperando conexiones';
        EventLogger.log('Servidor iniciado en puerto 8080', 'success');
        EventLogger.log('Estado: LISTENING - Servidor listo para aceptar conexiones', 'system');
    }

    stopServer() {
        Socket.stop();
        document.getElementById('startServer').disabled = false;
        document.getElementById('stopServer').disabled = true;
        document.getElementById('connectClient').disabled = false;
        document.getElementById('disconnectClient').disabled = true;
        document.getElementById('statusDot').classList.remove('active');
        document.getElementById('statusText').textContent = 'Servidor detenido';
        this.resetNodeStates();
        EventLogger.log('Servidor detenido', 'warning');
    }

    resetNodeStates() {
        const nodes = ['clientNode', 'serverNode'];
        nodes.forEach(node => {
            document.getElementById(node).classList.remove('connected');
        });
        PacketVisualizer.setActive(false);
    }

    connectClient() {
        EventLogger.log('Intentando establecer conexión...', 'system');
        
        if (!Socket.serverStatus) {
            EventLogger.log('Error: Servidor no está activo', 'attack');
            return;
        }
        
        const result = Socket.connect();
        EventLogger.log(`Socket result: ${result.success ? 'CONEXIÓN ESTABLECIDA' : 'FALLO'}`, 'success');
        
        this.activeConnections++;
        this.updateUIForConnection(true);
        EventLogger.log('Cliente conectado - Socket establecido', 'success');
        EventLogger.log('Estado: CONNECTED - Transferencia de datos activa', 'system');
        
        this.simulatePacketFlow();
    }

    disconnectClient() {
        Socket.disconnect();
        this.activeConnections--;
        this.updateUIForConnection(false);
        EventLogger.log('Cliente desconectado', 'warning');
    }

    updateUIForConnection(connected) {
        document.getElementById('connectClient').disabled = connected;
        document.getElementById('disconnectClient').disabled = !connected;
        document.getElementById('clientNode').classList.toggle('connected', connected);
        document.getElementById('serverNode').classList.toggle('connected', connected);
        PacketVisualizer.setActive(connected);
        document.getElementById('clientStatus').classList.toggle('online', connected);
        document.getElementById('serverStatus').classList.toggle('online', connected);
        this.updateStats();
    }

    simulatePacketFlow() {
        if (!Socket.isConnected()) return;

        PacketVisualizer.animatePacket();
        
        setTimeout(() => {
            if (Socket.isConnected()) {
                this.simulatePacketFlow();
            }
        }, 800 + Math.random() * 1200);
    }

    sendLoad() {
        if (!Socket.isConnected()) {
            EventLogger.log('Error: Cliente no conectado', 'attack');
            return;
        }

        const count = parseInt(document.getElementById('requestCount').value);
        this.queueLength = count;
        EventLogger.log(`Enviando ${count} solicitudes concurrentes...`, 'system');

        for (let i = 0; i < count; i++) {
            setTimeout(() => {
                if (Socket.isConnected()) {
                    this.processRequest(i + 1);
                }
            }, i * 100);
        }

        this.updateTransferRate(count);
    }

    processRequest(id) {
        EventLogger.log(`Procesando solicitud #${id}`, 'success');
        this.queueLength--;

        const worker = WorkerPool.getAvailable();
        setTimeout(() => {
            WorkerPool.release(worker);
            EventLogger.log(`Solicitud #${id} completada por hilo ${worker.id}`, 'success');
            this.updateStats();
        }, 1000 + Math.random() * 500);
    }

    updateTransferRate(requestCount) {
        this.transferRate = requestCount;
        this.updateStats();
        setTimeout(() => {
            this.transferRate = 0;
            this.updateStats();
        }, 2000);
    }

    aiOptimize() {
        if (WorkerPool.aiData.trafficPatterns.length === 0) {
            EventLogger.log('IA: No hay patrones de tráfico para analizar', 'warning');
            return;
        }

        const { peakWorkers, otherWorkers } = WorkerPool.rebalance();
        EventLogger.log(`IA: Balanceando carga - Workers más activos: ${peakWorkers.join(', ')}`, 'success');
        
        if (otherWorkers.length > 0) {
            EventLogger.log(`IA: Reasignando tareas a workers ${otherWorkers.join(', ')}`, 'success');
        }
        EventLogger.log('IA: Optimización completada - Distribución de carga ajustada', 'success');
    }

    executeAttack() {
        const attackType = document.getElementById('attackType').value;
        let message = '';

        switch (attackType) {
            case 'replay':
                message = 'ATAQUE DE REPETICIÓN: Paquetes duplicados enviados';
                if (DefenseSystem.isDefenseActive('timestamps')) {
                    EventLogger.log('DEFENSA TIME STAMPING: Paquetes rechazados (timestamp inválido)', 'defense');
                    EventLogger.log('Ataque mitigado exitosamente', 'success');
                    return;
                }
                break;
            case 'mitm':
                message = 'MAN-IN-THE-MIDDLE: Interceptando comunicación';
                if (DefenseSystem.isDefenseActive('hsm')) {
                    EventLogger.log('DEFENSA HSM/TPM: Conexión encriptada detectada, ataque fallido', 'defense');
                    EventLogger.log('Ataque mitigado exitosamente', 'success');
                    return;
                }
                break;
            case 'dos':
                message = 'ATAQUE DoS: Inundando servidor con solicitudes';
                this.queueLength += 50;
                this.updateStats();
                break;
        }

        EventLogger.log(message, 'attack');
        
        if (attackType !== 'dos') {
            this.compromiseIntegrity();
        }
    }

    compromiseIntegrity() {
        EventLogger.log('Advertencia: Integridad de información comprometida', 'warning');
    }

    applyDefense() {
        EventLogger.log('Aplicando estrategias de defensa...', 'defense');
        
        setTimeout(() => {
            EventLogger.log('Firewall activado - Filtrando paquetes maliciosos', 'defense');
            EventLogger.log('Monitoreo de integridad habilitado', 'defense');
            EventLogger.log('Defensa aplicada exitosamente', 'success');
        }, 500);
    }

    toggleTimestamps() {
        const active = DefenseSystem.toggleTimestamps();
        const btn = document.getElementById('enableTimestamps');
        btn.classList.toggle('defense-active', active);
        btn.textContent = active ? 'Time Stamping ON' : 'Time Stamping OFF';
        EventLogger.log(`Time Stamping ${active ? 'habilitado' : 'desactivado'}`, 'defense');
    }

    toggleNonRepudiation() {
        const active = DefenseSystem.toggleNonRepudiation();
        const btn = document.getElementById('enableNonRepudiation');
        btn.classList.toggle('defense-active', active);
        btn.textContent = active ? 'No Repudio ON' : 'No Repudio OFF';
        EventLogger.log(`No Repudio ${active ? 'habilitado' : 'desactivado'}`, 'defense');
        
        if (active) {
            EventLogger.log('Firma digital habilitada para todas las transacciones', 'defense');
        }
    }

    toggleHSM() {
        const active = DefenseSystem.toggleHSM();
        const btn = document.getElementById('enableHSM');
        btn.classList.toggle('defense-active', active);
        btn.textContent = active ? 'HSM/TPM ON' : 'HSM/TPM OFF';
        EventLogger.log(`Protección HSM/TPM ${active ? 'habilitada' : 'desactivada'}`, 'defense');
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.simulator = new NetworkManager();
});