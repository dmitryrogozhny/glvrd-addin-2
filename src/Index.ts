import { startApplication, GlvrdApp } from "./ElmApp";
import { spellCheck } from "./GlvrdService";

import "./css/main.css";

(() => {
    Office.initialize = () => {
        const onProofreadRequest: (text: string) => void = (text) => {
            spellCheck(text).then((suggestions) => {
                app.ports.suggestions.send(suggestions);
            }).catch((error) => {
                app.ports.externalError.send(error);
            });
        };

        const onSelectionChange: () => void = () => {
            Office.context.document.getSelectedDataAsync(Office.CoercionType.Text, (asyncResult: Office.AsyncResult) => {
                if (asyncResult.status === Office.AsyncResultStatus.Failed) {
                    app.ports.externalError.send(asyncResult.error.message);
                } else {
                    // the Office API returns paragraphs separated with \r symbol.
                    // replace \r with \n, i.e. carriage return with new line
                    const selectedText: string = asyncResult.value.replace(/\r/gi, "\n");

                    app.ports.textChanged.send(selectedText);
                }
            });
        };

        Office.context.document.addHandlerAsync(Office.EventType.DocumentSelectionChanged, onSelectionChange);

        const app: GlvrdApp = startApplication({ language: Office.context.displayLanguage });
        app.ports.check.subscribe(onProofreadRequest);

        // trigger selected text check in case a user selected a text first and then opened the addin
        onSelectionChange();
    };
})();
