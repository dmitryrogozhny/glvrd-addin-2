import { IProofreadResult } from "./GlvrdService";

import * as Elm from "./app/Main.elm";

export interface IAppParameters {
    language: string;
}

export interface IJstoElmPort<T> {
    send: (params: T) => void;
}

export interface IElmToJsPort<T> {
    subscribe: (callback: T) => void;
}

export type GlvrdApp = {
    ports: {
        suggestions: IJstoElmPort<IProofreadResult>;
        externalError: IJstoElmPort<string>;
        check: IElmToJsPort<(text: string) => void>;
        textChanged: IJstoElmPort<string>;
    };
};


export const startApplication: (parameters : IAppParameters) => GlvrdApp = (parameters) => {
    return Elm.Main.fullscreen(parameters);
};
