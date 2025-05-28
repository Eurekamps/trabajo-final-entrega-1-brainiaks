# triboo

An app to rule them all, one app to find them, One app to bring them all, and in the darkness bind them; In the Land of Mordor where the shadows lie.

# 🚀 Triboo - Plataforma Inteligente para Comunidades Virtuales

Triboo es una plataforma desarrollada por **BrainiaKs** orientada a la **gestión, dinamización y monetización de comunidades digitales**. A través de su arquitectura cloud, su asistente virtual inteligente *Brainito*, y un sistema de recompensas configurable, Triboo permite a líderes de comunidad optimizar la interacción, organización y fidelización de sus miembros.

Diseñada para ser **multiplataforma, escalable y accesible**, Triboo representa un nuevo estándar en la gestión comunitaria.

----------------------------------------------------------------------------------------------------------------------------------------------

## 🧠 ¿Qué es Triboo?

Triboo es mucho más que una app de chat. Es un **ecosistema digital colaborativo** que integra:

- 💬 Gestión de canales y comunidades temáticas
- 🤖 Asistente virtual Brainito (IA) para tareas automatizadas
- 🏆 Sistema de gamificación con puntos, niveles e insignias
- 📈 Analítica de participación y rendimiento comunitario
- 🌍 Acceso multiplataforma (Web, Android, iOS)
- 🛡️ Seguridad basada en roles y autenticación con Firebase

----------------------------------------------------------------------------------------------------------------------------------------------

## 🌍 Contexto y motivación

El auge de las comunidades digitales en entornos como la educación, las redes sociales, los equipos distribuidos o los colectivos de interés ha evidenciado una carencia: **no existen herramientas unificadas que permitan gestionarlas de forma eficiente, personalizada y rentable**. Triboo surge como respuesta a esta necesidad, proponiendo una solución integral:

- Comunicaciones estructuradas y asincrónicas
- Automatización a través de IA (Brainito)
- Paneles analíticos con métricas clave
- Incentivos y recompensas configurables
- Monetización mediante suscripciones y premium features

----------------------------------------------------------------------------------------------------------------------------------------------

## 🎯 Objetivos del proyecto

1. **Unificar herramientas** dispersas (chat, automatización, métricas, recompensas) en una sola app.
2. **Fomentar el crecimiento comunitario** mediante misiones, eventos, y participación gamificada.
3. **Reducir la carga operativa** de los líderes con asistencia virtual.
4. **Monetizar audiencias y fomentar la fidelización** con lógica freemium.
5. **Ofrecer una experiencia accesible, intuitiva y adaptativa** para todo tipo de usuarios.

---

## 🛠 Tecnologías principales

| Tecnología | Función |
|------------|---------|
| Flutter     | Desarrollo multiplataforma |
| Firebase    | Backend serverless (Auth, Firestore, Hosting, FCM) |
| Brainito    | Asistente IA con lógica conversacional y automatización |
| Stripe API  | Monetización de comunidades (plan premium) |
| Figma       | Diseño UI/UX |
| Trello      | Metodología Scrum / Kanban para desarrollo ágil |

---

## 🔑 Características principales

### Para administradores:
- Crear comunidades, gestionar roles y moderar usuarios.
- Configurar recompensas, misiones e insignias.
- Automatizar flujos y tareas repetitivas con Brainito.
- Visualizar métricas clave: retención, engagement, actividad.

### Para miembros:
- Participar en canales de conversación.
- Completar misiones y ganar recompensas.
- Gestionar su perfil, progreso e interacciones.
- Personalizar la experiencia con idioma y tema claro/oscuro.

### Para patrocinadores/empresas:
- Seguir comunidades afiliadas.
- Promocionar eventos u ofertas.
- Consultar actividad de usuarios vinculados.

----------------------------------------------------------------------------------------------------------------------------------------------

### 🤖 Inteligencia Artificial

- **Brainito**: asistente modular programable por el administrador (basado en reglas y lógica condicional; integrable con APIs conversacionales como Dialogflow)

### 💳 Monetización

- **Stripe API**: integración para pagos seguros, suscripciones y upgrades

### 📱 Frontend

- **Flutter + Dart**: app responsive multiplataforma
- Diseño adaptativo (modo claro/oscuro)

----------------------------------------------------------------------------------------------------------------------------------------------

## 🧠 ¿Cómo funciona Triboo?

Triboo funciona como una aplicación Flutter conectada a Firebase. Sus componentes principales son:

### 🔐 Autenticación y perfiles

- Firebase Authentication gestiona el acceso con roles diferenciados.
- El modelo `FbPerfil` contiene nombre, apodo, imagen y cumpleaños.
- Los usuarios pueden actualizar su perfil desde `ChangeProfileView`.

### 🏘️ Gestión de Comunidades

Las comunidades se estructuran mediante `FbCommunity` y almacenan:

- UID del creador y moderadores
- Lista de participantes
- Nombre, descripción, imagen y categoría

Cada usuario puede unirse a múltiples comunidades.

### 💬 Comunicación en tiempo real

- Chats públicos/privados gestionados desde `ChatsListScreenView`
- Búsqueda integrada por nombre de canal o comunidad
- Envío y lectura en tiempo real gracias a Firestore

### 🤖 Asistente Virtual: Brainito

**Brainito** automatiza procesos como:

- Responder dudas comunes
- Notificar eventos y retos
- Gestionar tareas o lanzamientos automáticos
- Funciona mediante lógica programable, ampliable con APIs externas

### 🏆 Sistema de Recompensas y Gamificación

- Recompensas configurables por comunidad (puntos, badges, retos)
- Seguimiento individual de progreso
- Rankings internos por actividad

### 📊 Estadísticas y Analítica

- Paneles de métricas en tiempo real (usuarios activos, participación)
- Visualización por canal, usuario o comunidad
- Exportación de informes (en planes avanzados)

### 🌐 Personalización y accesibilidad

- Temas claro/oscuro con `ThemeProvider`
- Soporte multilingüe (`app_localizations.dart`)
- Interfaz responsive para móvil y web

----------------------------------------------------------------------------------------------------------------------------------------------

## 🚀 Ciclo de vida de la app

1. **Inicio (`main.dart`)**  
   El punto de entrada de la app. Inicializa Firebase, configura los servicios necesarios y lanza la instancia principal `TribooApp`.

2. **Carga de la app (`Apps/Triboo.dart`)**  
   Aquí se define el `MaterialApp`, que establece:
   - La configuración del idioma (mediante `AppLocalizations`)
   - El tema visual (claro u oscuro)
   - Las rutas principales a todas las pantallas

3. **Pantalla de bienvenida: `SplashView`**  
   Una pantalla de transición que verifica si el usuario ya ha iniciado sesión.  
   - Si **no está autenticado**, lo redirige a `LoginView`.
   - Si **está autenticado**, lo lleva a la pantalla principal correspondiente (`HomeView` o `HomerView`, según su rol).

4. **Autenticación: `LoginView` / `RegisterView`**  
   - `LoginView` permite que un usuario existente inicie sesión con email y contraseña.
   - `RegisterView` permite que un nuevo usuario cree una cuenta y configure un perfil inicial.
   - Tras registrarse o iniciar sesión exitosamente, **se almacena su información en Firestore y se le redirige al núcleo funcional de la app.**

----------------------------------------------------------------------------------------------------------------------------------------------

### 🎯 Acceso a funcionalidades clave tras autenticación

Una vez autenticado, el usuario accede al **centro de control de la aplicación**, desde donde puede interactuar con:

----------------------------------------------------------------------------------------------------------------------------------------------

### 🏘️ **Gestión y exploración de Comunidades**

- El usuario accede a una vista donde puede:
  - **Explorar comunidades públicas** (filtradas por categoría o relevancia)
  - **Ver las comunidades a las que ya pertenece**
  - **Unirse a nuevas comunidades o crear la suya propia**
- Cada comunidad actúa como un "hub" independiente:
  - Tiene su propio chat, configuraciones, reglas, recompensas y asistentes.
  - Puede contener **eventos**, **retos**, **contenido exclusivo** y mensajes del administrador.

👉 **Esto convierte a Triboo en una plataforma altamente personalizable**, donde cada comunidad tiene su propio entorno, facilitando la creación de subgrupos, talleres, o espacios de interés.

----------------------------------------------------------------------------------------------------------------------------------------------

### 💬 **Chats Directos y Colaboración en Tiempo Real**

Desde la vista principal o desde dentro de una comunidad, el usuario puede:

- Acceder a **chats comunitarios** organizados por canal temático.
- **Iniciar conversaciones directas** con otros miembros.
- Usar el buscador para encontrar chats, usuarios o temas específicos.
- Enviar y recibir mensajes en **tiempo real** gracias a Firestore.
- Acceder al **historial completo** del canal o conversación privada.

🔔 También se integran **notificaciones push** que alertan al usuario de nuevos mensajes o eventos relevantes, incluso si la app está cerrada.

----------------------------------------------------------------------------------------------------------------------------------------------

### 🔄 Vistas disponibles tras login

Estas son algunas de las rutas activadas en el flujo autenticado:

- `/HomeView` → vista central con acceso a comunidades y menú lateral
- `/CommunityDetailView` → detalle de una comunidad específica
- `/ChatDetailScreen` → ventana de chat individual
- `/MyCommunitiesView` → resumen de comunidades propias
- `/ChangeProfileView` → edición de perfil
- `/ProfileUserView` → visualización del perfil propio o ajeno

----------------------------------------------------------------------------------------------------------------------------------------------

### 🔐 Control de acceso

Cada pantalla o funcionalidad se protege según el estado del usuario:
- Solo usuarios autenticados pueden acceder a `/HomeView` o comunidades.
- Cada acción en una comunidad está filtrada por **rol** (miembro, moderador, admin).
- Los datos personales están protegidos y solo pueden ser modificados por el propio usuario.

-----------------------------------------------------------------------------------------------------------------------------------------------

⚠️ **Importancia crítica de esta etapa**:
> Todo el valor de la app se desbloquea una vez que el usuario accede a su espacio personal: comunidades, chats, recompensas, estadísticas.  
> Triboo no es solo una red, sino un sistema de **ecosistemas virtuales independientes**, donde cada usuario es parte activa.


----------------------------------------------------------------------------------------------------------------------------------------------

## 📦 Estructura del Proyecto

```bash
triboo/
├── android/               # Proyecto Android
├── ios/                   # Proyecto iOS
├── lib/                   # Código fuente en Dart
│   ├── models/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── assets/                # Recursos (iconos, traducciones)
├── firebase.json          # Configuración Firebase
├── pubspec.yaml           # Dependencias y metadatos
└── README.md              # (Tú estás aquí)

