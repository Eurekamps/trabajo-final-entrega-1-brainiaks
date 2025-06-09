import { onRequest } from "firebase-functions/v2/https";
import logger from "firebase-functions/logger";
import express from "express";
import cors from "cors";
import admin from "firebase-admin";
import fetch from "node-fetch";

admin.initializeApp();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.post("/", async (req, res) => {
  const { chatId, mensaje } = req.body;

  if (!chatId || !mensaje) {
    return res.status(400).json({ error: "Faltan argumentos" });
  }

  try {
    const WIT_AI_TOKEN = "Bearer 7IRYCFACRLJPRV36OYAQVGCLGHY5UW2A";

    const response = await fetch(
      `https://api.wit.ai/message?v=20230526&q=${encodeURIComponent(mensaje)}`,
      {
        headers: {
          Authorization: WIT_AI_TOKEN,
        },
      }
    );

    const witData = await response.json();
    console.log("Respuesta de Wit.ai:", witData);

    const textoIA = interpretarRespuesta(witData);

    await admin
      .firestore()
      .collection("chats")
      .doc(chatId)
      .collection("mensajes")
      .add({
        texto: textoIA,
        autorId: "IA",
        fecha: admin.firestore.Timestamp.now(),
        visto: false,
        gustado: false,
      });

    return res.status(200).json({ success: true });
  } catch (e) {
    console.error("Error interno:", e);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

function interpretarRespuesta(witData) {
  const intent = witData.intents?.[0]?.name ?? "desconocido";
  const entities = witData.entities ?? {};

  // Resolver operación con 3 entidades: num1, simbolo, num2
  if (intent === "resolver_matematicas") {
    const num1 = parseFloat(entities["num1:num1"]?.[0]?.body);
    const num2 = parseFloat(entities["num2:num2"]?.[0]?.body);
    const simbolo = entities["simbolo:simbolo"]?.[0]?.body;

    if (isNaN(num1) || isNaN(num2) || !simbolo) {
      return "No entendí bien la operación. Asegúrate de escribir dos números y un símbolo.";
    }

    let resultado;
    switch (simbolo.trim()) {
      case "+":
      case "más":
        resultado = num1 + num2;
        break;
      case "-":
      case "menos":
        resultado = num1 - num2;
        break;
      case "*":
      case "x":
      case "por":
        resultado = num1 * num2;
        break;
      case "/":
      case "dividido":
      case "entre":
        resultado = num2 !== 0 ? num1 / num2 : "infinito";
        break;
      default:
        return `No reconozco el operador "${simbolo}". Usa +, -, *, / u operaciones como 'por' o 'entre'.`;
    }

    return `El resultado de ${num1} ${simbolo} ${num2} es: ${resultado}`;
  }

  // Respuestas predefinidas para otras intenciones
  const respuestas = {
    saludo: [
      "¡Hola! Soy Brainito, ¿en qué puedo ayudarte hoy?",
      "¡Hey! Bienvenido a Triboo 😊",
      "¡Hola hola! ¿Necesitas ayuda con algo?",
    ],
    despedida: [
      "¡Hasta luego! No dudes en volver si necesitas ayuda.",
      "¡Chao! Estoy aquí si me necesitas de nuevo.",
      "Que tengas un buen día. ¡Nos vemos pronto!",
    ],
    crear_post: [
      "Para crear un post, entra en una comunidad y usa el botón flotante abajo a la derecha.",
      "Recuerda: los posts se crean dentro de cada comunidad, no desde la pestaña 'Todos'.",
      "Ve a la comunidad que te interese y pulsa el botón de abajo a la derecha para publicar.",
    ],
    pedir_ayuda: [
      "Triboo es una red social basada en comunidades. Yo soy Brainito, tu asistente virtual 🤖.",
      "¿Dudas sobre Triboo? Soy Brainito y estoy aquí para ayudarte.",
      "Soy Brainito y puedo explicarte cómo funciona Triboo. ¡Pregunta sin miedo!",
    ],
    chiste: [
      "¿Por qué el libro de matemáticas está triste? Porque tiene demasiados problemas.",
      "—¡Camarero! Este filete tiene muchos nervios. —Normal, es la primera vez que se lo comen.",
      "¿Qué hace un pez? ¡Nada!",
      "¿Cuál es el café más peligroso del mundo? El ex-preso.",
      "¿Qué le dice una impresora a otra? ¿Esa hoja es tuya o es una impresión mía?",
      "¿Cómo se despiden los químicos? Ácido un placer.",
      "¿Por qué los esqueletos no pelean entre ellos? Porque no tienen agallas.",
      "—¿Qué hace una vaca en un terremoto? —¡Leche agitada!",
      "¿Cuál es el animal más antiguo? La cebra, porque está en blanco y negro. (¡no lo podía sacar 😂!)",
      "¿Qué hace una abeja en el gimnasio? ¡Zum-ba!",
    ],
    motivacion_frase: [
      "No tienes que ser perfecto, solo constante.",
      "El éxito es la suma de pequeños esfuerzos repetidos cada día.",
      "Si puedes soñarlo, puedes lograrlo.",
      "Los límites solo existen si tú los aceptas.",
      "Cada día es una nueva oportunidad para empezar de nuevo.",
      "No te compares con los demás, compárate con quien eras ayer.",
      "Nunca es tarde para ser quien podrías haber sido.",
      "Avanza aunque sea un paso pequeño, pero no te detengas.",
      "Confía en ti, eres más capaz de lo que crees.",
      "A veces no necesitas motivación, solo empezar.",
    ],
    desconocido: [
      "Hmm... no entendí muy bien. ¿Podrías preguntarlo de otra forma?",
      "No estoy seguro de cómo ayudarte con eso. ¿Lo intentas de nuevo?",
      "Lo siento, no entendí tu intención. ¿Puedes reformular tu mensaje?",
    ],
  };

  const posiblesRespuestas = respuestas[intent] || respuestas["desconocido"];
  const indice = Math.floor(Math.random() * posiblesRespuestas.length);
  return posiblesRespuestas[indice];
}




export const mensajeAIA = onRequest(app);
