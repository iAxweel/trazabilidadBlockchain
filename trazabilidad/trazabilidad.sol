// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract Administracion {
    
    // Direccion del REGULADOR_GUBERNAMENTAL -> Owner / Dueño del contrato 
    address public REGULADOR_GUBERNAMENTAL;
    
    // Constructor del contrato 
    constructor () public {
        REGULADOR_GUBERNAMENTAL = msg.sender;
    }
    
    // Mapping para relacionar las empresas de produccion, procesamiento, logistica y ventas (direccion/address) con la validez del sistema de administracion
    mapping (address => bool) public Validacion_Empresa;
    
    // Relacionar una direccion de una empresa con su contrato 
    mapping (address => address) public EmpresaProduccion_Contrato;
    
    // Ejemplo 1: 0x27031a7e3F4ce7Ef1d86709adce4bb81cEe65fe6 -> true = TIENE PERMISOS PARA CREAR SU SMART CONTRACT
    // Ejemplo 2: 0x766E18ed2511efcA09A4Ee7522823f3aD272A60a -> false = NO TIENE PERMISOS PARA CREAR SU SMART CONTRACT
    
    // Array de direcciones que almacene los contratos de las empresas validadas 
    address [] public direcciones_contratos_empresas;
    
    // Array de las direcciones que soliciten acceso 
    address [] Solicitudes;
    
    // Eventos a emitir 
    event SolicitudAcceso (address);
    event NuevaEmpresaValidada (address);
    event NuevoContrato (address, address);
    
    
    // Modificador que permita unicamente la ejecucion de funciones por el REGULADOR_GUBERNAMENTAL 
    modifier UnicamenteReguladorGubernamental(address _direccion) {
        require(_direccion == REGULADOR_GUBERNAMENTAL, "Solo el regulador puede operar.");
        _;
    }
    
    // Funcion para solicitar acceso al sistema de trazabilidad 
    function SolicitarAcceso() public {
        // Almacenar la direccion en el array de solicitudes 
        Solicitudes.push(msg.sender);
        // Emision del evento 
        emit SolicitudAcceso (msg.sender);
    }
    
    // Funcion que visualiza las direcciones que han solicitado este acceso 
    function VisualizarSolicitudes() public view UnicamenteReguladorGubernamental(msg.sender) returns (address [] memory){
        return Solicitudes;
    }
    
    // Funcion para validar nuevas empresas puedan autogestionarse -> UnicamenteReguladorGubernamental
    function registroUsuario (address _empresa, string memory _tipoEmpresa) public UnicamenteReguladorGubernamental(msg.sender) {
        string [4] memory tipoEmpresa = ["Produccion", "Procesamiento", "Logistica", "Ventas"];
        // Asignacion del estado de validez a una empresa
        for (uint32 i = 0; i < tipoEmpresa.length; i++){
            if(keccak256(abi.encodePacked((_tipoEmpresa))) == keccak256(abi.encodePacked((tipoEmpresa[i])))){
                Validacion_Empresa[_empresa] = true;
                // Emision del evento 
                emit NuevaEmpresaValidada(_empresa);
            }
        } 
    }
    
    // Funcion que permita crear un contrato inteligente de una empresa
    function FactoryEmpresa() public {
        // Filtrado para que unicamente las empresas validadas sean capaces de ejecutar esta funcion 
        require (Validacion_Empresa[msg.sender] == true, "No tiene permiso para ejecutar esta funcion.");
        // Generar un Smart Contract -> Generar su direccion 
        address contrato_Empresa = address (new Produccion(msg.sender));
        // Almacenamiento la direccion del contrato en el array 
        direcciones_contratos_empresas.push(contrato_Empresa);
        // Relacion entre la empresa y su contrato 
        EmpresaProduccion_Contrato[msg.sender] = contrato_Empresa;
        // Emision del evento 
        emit NuevoContrato(contrato_Empresa, msg.sender);
    }
    
    
}


// Contrato autogestionable por la empresa de produccion
contract Produccion {
    
    // Direcciones iniciales 
    address public DireccionEmpresa;
    address public DireccionContrato;
    
    constructor (address _direccion) public {
        DireccionEmpresa = _direccion;
        DireccionContrato = address(this);
    }
    
    // Mapping para relacionar el hash de la persona con los resultados (origenSemillas, entornoCrecimiento, procesoSiembra, CodigoIPFS)
    mapping (bytes32 => ProductoAgricola) ResultadosProdAgricola;
    
    // Estructura de los resultados 
    struct ProductoAgricola {
        string origenSemillas;
        string entornoCrecimiento;
        string procesoSiembra;
        string CodigoIPFS;
    }
    
    // Eventos
    event NuevoResultado (string, string, string, string);
    
    // Filtrar las funciones a ejecutar por la empresa de produccion
    modifier UnicamenteEmpresaProduccion(address _direccion) {
        require (_direccion == DireccionEmpresa, "No tiene permisos para ejecutar esta funcion.");
        _;
    }
    
    // Funcion para emitir un resultado de un producto agricola
    // Formato de los campos de entrada: | 19120185X | Morelia | Adecuado | Completo | QmVcB3RnQQoLFYMCBfosxA8NQMCHtgjKNcr24Ngbg46XTq
    function ResultadosProductoAgricola(string memory _idProductoAgricola, string memory _origenSemillas, string memory _entornoCrecimiento, string memory _procesoSiembra, string memory _codigoIPFS) public UnicamenteEmpresaProduccion(msg.sender){
        // Hash de la identificacion de la persona 
        bytes32 hash_idProductoAgricola = keccak256 (abi.encodePacked(_idProductoAgricola));
        // Relacion del hash de la persona con la estructura de resultados 
        ResultadosProdAgricola[hash_idProductoAgricola] = ProductoAgricola(_origenSemillas, _entornoCrecimiento, _procesoSiembra, _codigoIPFS);
        // Emision de un evento 
        emit NuevoResultado(_origenSemillas, _entornoCrecimiento, _procesoSiembra, _codigoIPFS);
    }
    
    // Funcion que permita la visualizacion de los resultados 
    function VisualizarResultados(string memory _idProductoAgricola) public view returns (string memory _origenSemillas, string memory _entornoCrecimiento, string memory _procesoSiembra, string memory _codigoIPFS) {
        // Hash de la identidad de la persona 
        bytes32 hash_idProductoAgricola = keccak256 (abi.encodePacked(_idProductoAgricola));
 
        // Retorno de los parametros necesarios
        _origenSemillas = ResultadosProdAgricola[hash_idProductoAgricola].origenSemillas;
        _entornoCrecimiento = ResultadosProdAgricola[hash_idProductoAgricola].entornoCrecimiento;
        _procesoSiembra = ResultadosProdAgricola[hash_idProductoAgricola].procesoSiembra;
        _codigoIPFS = ResultadosProdAgricola[hash_idProductoAgricola].CodigoIPFS;
    }
    
    
}


