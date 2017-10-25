var glvrd: IGlvrdService = (<any>window).glvrd;

interface IGlvrdService {
    getStatus: (callback: (result: IRequestResult) => void) => void;
    proofread: (text: string, callback: (result: IProofreadResult) => void) => void;
}

interface IRequestResult {
    status: "ok" | string;
    message: string | null;
}

export interface IProofreadResult extends IRequestResult {
    score: string;
    fragments: Array<IProofreadComment>;
}

export interface IProofreadComment {
    start: number;
    end: number;
    url: string;
    hint: { description: string, name: string };
}

const okStatus: string = "ok";

export const spellCheck: (text: string) => Promise<IProofreadResult> = (text: string) => {
    return new Promise<IProofreadResult>((resolve, reject) => {
        if (glvrd !== undefined) {
            glvrd.getStatus((status) => {
                if (status.status === okStatus) {
                    glvrd.proofread(text, (result) => {
                        if (result.status === okStatus) {
                            result = formatResult(result);
                            resolve(result);
                        } else {
                            reject(result.message);
                        }
                    });
                } else {
                    reject(status.message);
                }
            });
        } else {
            reject("glvrd service is not available");
        }
    });
};

const formatResult: (result: IProofreadResult) => IProofreadResult = (result) => {
    // glvrd service returns hints containing "&nbsp;" strings in text
    // replace "&nbsp;" with spaces
    for (let fragment of result.fragments) {
        fragment.hint.name = fragment.hint.name.replace(/&nbsp;/gi, " ");
        fragment.hint.description = fragment.hint.description.replace(/&nbsp;/gi, " ");
    }

    // glvrd service returns score as string for float values, and as integer for int (i.e. "4.5" and 5)
    // always convert score to be string
    const score: string = result.score.toString();
    result.score = score;

    return result;
};
