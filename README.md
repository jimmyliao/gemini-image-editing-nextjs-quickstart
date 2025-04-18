# Gemini 圖片生成和編輯 Next.js 快速入門, 並部署至 Google Cloud Run

本快速入門展示了如何使用 Google Gemini 2.0 Flash 模型透過 Next.js 和 React 建立一個圖片生成和編輯應用程式。
並將應用程式部署至 Google Cloud Run

這個應用程式允許您：

1.  **生成圖片：** 輸入文字提示以生成新圖片。
2.  **編輯圖片：** 上傳現有圖片並提供文字提示以進行修改。
3.  **對話紀錄：** 維護對話紀錄以進行圖片的反覆修改。
4.  **部署至 Google Cloud Run**：將應用程式部署至 Google Cloud Run 以供使用。

## 架構

此應用程式使用以下技術構建：

*   **前端：** Next.js (React 框架)
*   **後端 API：** Next.js API 路由
*   **AI 模型：** Google Gemini 2.0 Flash (透過 `@google/genai` SDK)
*   **樣式：** Tailwind CSS
*   **部署：** Google Cloud Run (使用 Docker)

## 設定

1.  **複製儲存庫：**

    ```bash
    git clone https://github.com/your-username/gemini-image-editing-nextjs-quickstart.git
    cd gemini-image-editing-nextjs-quickstart
    ```

2.  **設定環境變數：**

    *   複製範例環境檔案：
        ```bash
        cp .env.example .env
        ```
    *   編輯 `.env` 檔案並加入您的：
        *   `GEMINI_API_KEY`: 您的 [Google AI Studio API 金鑰](https://aistudio.google.com/app/apikey)。
        *   `PROJECT`: 您的 Google Cloud 專案 ID。
        *   `LOCATION`: 您要部署 Cloud Run 服務的 Google Cloud 區域 (例如 `us-central1` 或 `asia-east1`)。
        *   `SERVICE_NAME`: 您想要的 Cloud Run 服務名稱 (例如 `gemini-image-editing-app`)。

3.  **安裝依賴套件：**

    ```bash
    npm install
    ```
    或者，您可以使用 `make install`。

## 本地運行

若要在本地開發環境中運行應用程式：

```bash
npm run dev
```
或者，使用 `make run-local`。

這將在 `http://localhost:3000` 上啟動開發伺服器。

## 部署

### 使用 Makefile 部署到 Google Cloud Run

您可以使用提供的 `Makefile` 簡化部署到 Google Cloud Run 的流程。

**先決條件：**

1.  確保您的 `.env` 檔案已正確設定，包含 `PROJECT` (您的 Google Cloud 專案 ID)、`LOCATION` (您選擇的 Google Cloud 區域)、`SERVICE_NAME` (您希望的 Cloud Run 服務名稱) 以及 `GEMINI_API_KEY`。
2.  安裝並設定 [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install)。確保您已登入 (`gcloud auth login`) 並已設定預設專案 (`gcloud config set project YOUR_PROJECT_ID`)。

**部署步驟：**

1.  **建置映像檔並推送到 Artifact Registry：**

    ```bash
    make build-image
    ```

    此指令會：
    *   讀取您的 `.env` 檔案。
    *   使用 Cloud Build 建置 Docker 映像檔 (指定 `linux/amd64` 平台)。
    *   將建置好的映像檔推送到您專案的 Artifact Registry。

2.  **部署到 Cloud Run：**

    ```bash
    make deploy
    ```

    此指令會：
    *   讀取您的 `.env` 檔案。
    *   將先前建置的映像檔部署到 Google Cloud Run。
    *   設定必要的環境變數 (如 `GEMINI_API_KEY`)。
    *   允許未經身份驗證的調用 (如果您需要限制存取，請在部署後修改 Cloud Run 服務設定)。

部署完成後，指令會輸出您的 Cloud Run 服務 URL。

### Docker

1.  **建置 Docker 映像檔：**

    ```bash
    docker build -t nextjs-gemini-image-editing .
    ```

2.  **運行容器：**

    ```bash
    docker run -p 3000:3000 -e GEMINI_API_KEY=your_google_api_key nextjs-gemini-image-editing
    ```

    或者，您可以使用環境檔案：

    ```bash
    # 運行容器並使用環境檔案
    docker run -p 3000:3000 --env-file .env nextjs-gemini-image-editing
    ```

3.  **開啟應用程式：**

    在瀏覽器中開啟 [http://localhost:3000](http://localhost:3000)。

## Makefile 目標

`Makefile` 提供了幾個方便的目標：

*   `make init`: 檢查環境設定是否正確。
*   `make install`: 安裝 npm 依賴套件。
*   `make build`: 建置 Next.js 應用程式以用於生產環境。
*   `make run-local`: 在本地開發模式下運行應用程式。
*   `make build-image`: 建置 Docker 映像檔 (針對 `linux/amd64` 平台)。
*   `make push-image`: 將 Docker 映像檔推送到 GCR。
*   `make deploy`: 將應用程式部署到 Cloud Run (依賴 `push-image`)。
*   `make clean`: 移除建置產物 (`.next`) 和 `node_modules`。
*   `make help`: 顯示可用的 make 目標和設定變數。

## 授權條款

請參閱 [LICENSE](LICENSE) 檔案。

## 基本請求

對於想要直接呼叫 Gemini API 的開發人員，您可以使用 Google Generative AI JavaScript SDK：

```javascript
import { GoogleGenerativeAI } from "@google/genai";
import fs from "fs";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function generateImage() {
  const contents =
    "嗨，可以生成一張 3D 渲染的圖片，圖片中有一隻戴著禮帽的豬在飛行，背景是一個充滿綠意的未來城市。";

  // 設定 responseModalities 以包含 "Image"，使模型可以生成圖片
  const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash-exp",
    generationConfig: {
      responseModalities: ["Text", "Image"]
    }
  });

  try {
    const response = await model.generateContent(contents);
    for (const part of response.response.candidates[0].content.parts) {
      // 根據部分類型，顯示文字或儲存圖片
      if (part.text) {
        console.log(part.text);
      } else if (part.inlineData) {
        const imageData = part.inlineData.data;
        const buffer = Buffer.from(imageData, "base64");
        fs.writeFileSync("gemini-native-image.png", buffer);
        console.log("圖片儲存為 gemini-native-image.png");
      }
    }
  } catch (error) {
    console.error("生成內容錯誤:", error);
  }
}
```

## 功能

*   🎨 文字生成圖片
*   🖌️ 圖片編輯
*   💬 對話紀錄
*   📱 響應式 UI
*   🔄 無縫工作流程
*   ⚡ 使用 Gemini 2.0 Flash JavaScript SDK

## 快速入門

### 本地開發

1.  **複製範例環境檔案：**

    ```bash
    cp .env.example .env
    ```

2.  **設定環境變數：**

    *   在 `.env` 檔案中設定您的：
        *   `GEMINI_API_KEY`: 您的 [Google AI Studio API 金鑰](https://aistudio.google.com/app/apikey)。

3.  **安裝依賴套件：**

    ```bash
    npm install
    ```

4.  **運行開發伺服器：**

    ```bash
    npm run dev
    ```

5.  **開啟應用程式：**

    在瀏覽器中開啟 [http://localhost:3000](http://localhost:3000)。

## 部署

### Vercel

[![部署到 Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fgoogle-gemini%2Fgemini-image-editing-nextjs-quickstart&env=GEMINI_API_KEY&envDescription=Create%20an%20account%20and%20generate%20an%20API%20key&envLink=https%3A%2F%2Faistudio.google.com%2Fapp%2Fu%2F0%2Fapikey&demo-url=https%3A%2F%2Fhuggingface.co%2Fspaces%2Fphilschmid%2Fimage-generation-editing)

### Docker

1.  **建置 Docker 映像檔：**

    ```bash
    docker build -t nextjs-gemini-image-editing .
    ```

2.  **運行容器：**

    ```bash
    docker run -p 3000:3000 -e GEMINI_API_KEY=your_google_api_key nextjs-gemini-image-editing
    ```

    或者，您可以使用環境檔案：

    ```bash
    # 運行容器並使用環境檔案
    docker run -p 3000:3000 --env-file .env nextjs-gemini-image-editing
    ```

3.  **開啟應用程式：**

    在瀏覽器中開啟 [http://localhost:3000](http://localhost:3000)。

## 技術

*   [Next.js](https://nextjs.org/) - React 框架
*   [Google Gemini 2.0 Flash](https://deepmind.google/technologies/gemini/) - AI 模型
*   [shadcn/ui](https://ui.shadcn.com/) - 可重複使用的元件

## 授權條款

請參閱 [LICENSE](LICENSE) 檔案。
