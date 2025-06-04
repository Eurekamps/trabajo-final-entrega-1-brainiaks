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
  return `He detectado la intención: ${intent}`;
}

export const mensajeAIA = onRequest(app);
