unit uTextToSpeechAzure;

interface

uses
    System.SysUtils,
    System.Types,
    System.UITypes,
    System.Classes,
    System.Variants,
    System.IOUtils,
    System.StrUtils,
    System.Generics.Collections,

    // ... Test de requisição do token AZURE
    System.Net.HttpClient, //TNetHttp
    System.Net.URLClient, //TNetHttp
    System.Net.HttpClientComponent, //TNetHttp
    System.Net.Mime, //TMultipartFormData para enviar arquivos pro servidor
    System.JSON,
    Rest.Client,
    Rest.Types;

type
    {$SCOPEDENUMS ON}
    ELanguage = (ptBR, enUS, esES, zhCN, bnBD, ruRU, jaJP, paIN);
    ELanguageHelper = record Helper for ELanguage
        function ToString: String;
        function ToTexto: String;
    end;

    EVoiceStyle = (AdvertisementUpbeat, Affectionate, Angry, Assistant, Calm, Chat, Cheerful, Customerservice, Depressed, Disgruntled, DocumentaryNarration,
                Embarrassed, Empathetic, Envious, Excited, Fearful, Friendly, Gentle, Hopeful, Lyrical, NarrationProfessional, NarrationRelaxed, Newscast,
                NewscastCasual, NewscastFormal, PoetryReading, Sad, Serious, Shouting, SportsCommentary, SportsCommentaryExcited, Whispering,
                Terrified, Unfriendly);
    EVoiceStyleHelper = record Helper for EVoiceStyle
        function ToString: String;
        function ToTexto: String;
    end;

    // ... Formato de Audio suportados pelo Azure
    EAudioFormat = (// ... Streaming
                    AMRWB16000hz,
                    Audio16khz16bit32kbpsMonoOpus,
                    Audio16khz32kbitrateMonoMP3,
                    Audio16khz64kbitrateMonoMP3,
                    Audio16khz128kbitrateMonoM3,
                    Audio24khz16bit24kbpsMonoOpus,
                    Audio24khz16bit48kbpsMonoOpus,
                    Audio24khz48kbitrateMonoMP3,
                    Audio24khz96kbitrateMonoMP3,
                    Audio24khz160kbitrateMonoMP3,
                    Audio48khz96kbitrateMonoMP3,
                    Audio48khz192kbitrateMonoMP3,
                    Ogg16khz16bitMonoOpus,
                    Ogg24khz16bitMonoOpus,
                    Ogg48khz16bitMonoOpus,
                    Oaw8khz8bitMonoLaw,
                    Raw8khz8bitMonoMulaw,
                    Raw8khz16bitMonoPCM,
                    Raw16khz16bitMonoPCM,
                    Raw16khz16bitMonoTruesilk,
                    Raw22050hz16bitMonoPCM,
                    Raw24khz16bitMonoPCM,
                    Raw24khz16bitMonoTruesilk,
                    Raw44100hz16bitMonoPCM,
                    Raw48khz16bitMonoPCM,
                    Webm16khz16bitMonoOpus,
                    Webm24khz16bit24kbpsMonoOpus,
                    Webm24khz16bitMonoOpus,
                    // ... NonStreaming
                    Riff8khz8bitMonoAlaw,
                    Riff8khz8bitMonoMulaw,
                    Riff8khz16bitMonoPCM,
                    Riff22050hz16bitMonoPCM,
                    Riff24khz16bitMonoPCM,
                    Riff44100hz16bitMonoPCM,
                    Riff48khz16bitMonoPCM
                    );
    EAudioFormatHelper = record Helper for EAudioFormat
        function ToString: String;
    end;

    // ... Generos para filtagem da lista
    EGenero = (Male, Female);
    EGeneroHelper = record Helper for EGenero
        function ToString: String;
        function ToTexto: String;
    end;

    // ... Velocidades da narração
    ERateVoz = (xSlow, Slow, Medium, Fast, xFast, Default);
    ERateVozHelper = record Helper for ERateVoz
        function ToString: String;
    end;

    EPitch = (xlow, low, medium, high, xhigh, default);
    EPitchHelper = record Helper for EPitch
        function ToString: String;
    end;

    // ... Volume do áudio da narração
    EVolume = (silent, xSoft, soft, medium, loud, xLoud, default);
    EVolumeHelper = record Helper for EVolume
        function ToString: String;
    end;
    {$SCOPEDENUMS OFF}

    TVoice = record
        Name: String;
        DisplayName: String;
        LocalName: String;
        ShortName: String;
        Gender: String;
        Locale: String;
        LocaleName: String;
        VoiceType: String;
        Status: String;
    end;

    TListaVozes = class
    private
        FItems: TList<TVoice>;
        procedure SetItems(const Value: TList<TVoice>);
    public
        constructor Create;
        destructor Destroy;
        property Items: TList<TVoice> read FItems write SetItems;
        function ListName: TArray<String>;
    end;

    TTextToSpeechAzure = class
    private
        FToken: String;
        FTokenPlayer: String;
        FURLPegarToken: String;
        FURLPedirNarracao: String;
        FURLPedirListaVozes: String;
        FFormatoAudio: EAudioFormat;
        FTextoVozFeminina: String;
        FTextoVozMasculina: String;
        FLanguage: String;
        FVozesFemininas: TListaVozes;
        FVozesMasculinas: TListaVozes;
        function SolicitarToken: String;
    public
        constructor Create(aToken: String); overload;
        constructor Create(aToken: String; NewURLToken: String); overload;
        constructor Create(aToken: String; NewURLToken: String; NewURLService: String); overload;
        destructor Destroy;
        property Language: String read FLanguage write FLanguage;
        property VozesFemininas: TListaVozes read FVozesFemininas write FVozesFemininas;
        property VozesMasculinas: TListaVozes read FVozesMasculinas write FVozesMasculinas;
        property TextoVozFeminina: String read FTextoVozFeminina write FTextoVozFeminina;
        property TextoVozMasculina: String read FTextoVozMasculina write FTextoVozMasculina;
        property URLPedirListaVozes: String read FURLPedirListaVozes write FURLPedirListaVozes;
        function GetListaVozes: TArray<TVoice>; overload;
        function GetListaVozes(aLanguage: String): TArray<TVoice>; overload;
        function GetListaVozes(aLanguage: String; Gender: EGenero): TArray<TVoice>; overload;
        function GetListaVozes(aLanguage: String; NewURLLista: String): TArray<TVoice>; overload;
        function PegarNarracao(SSML: String; OutFormat: EAudioFormat): TMemoryStream;
    published
        property Token: String read FToken;
    end;

Const
    c_UTF8: String = 'utf-8';
    c_ContentType: String = '[{"Content-Type": "application/json"}]';

implementation

{ TTextToSpeechAzure }

function TTextToSpeechAzure.SolicitarToken: String;
var
    NetHTTPClient: TNetHTTPClient;
    BodyStream: TStringStream;
begin
    try
        // ... Pegar o Token de acesso
        BodyStream := TStringStream.Create('[{"Content-Type": "application/json"}]', TEncoding.UTF8);

        NetHTTPClient := TNetHTTPClient.Create(nil);
        try
            NetHTTPClient.AcceptEncoding := c_UTF8;
            NetHTTPClient.ContentType := 'application/x-www-form-urlencoded';
            NetHTTPClient.CustHeaders.Add('Ocp-Apim-Subscription-Key', FToken);
            Result := NetHTTPClient.Post(FURLPegarToken, BodyStream).ContentAsString(TEncoding.UTF8);
        finally
            BodyStream.DisposeOf;
            NetHTTPClient.DisposeOf;
        end;
    except on E: Exception do
        raise Exception.Create(E.Message);
    end;
end;

constructor TTextToSpeechAzure.Create(aToken: String);
var
    NetHTTPClient: TNetHTTPClient;
    BodyStream: TStringStream;
begin
    FToken := aToken;
    FURLPegarToken := 'https://brazilsouth.api.cognitive.microsoft.com/sts/v1.0/issueToken'; //Sempre verificar se a URL do serviço não mudou
    FURLPedirNarracao := 'https://brazilsouth.tts.speech.microsoft.com/cognitiveservices/v1';
    FURLPedirListaVozes := 'https://brazilsouth.tts.speech.microsoft.com/cognitiveservices/voices/list';
    FFormatoAudio := EAudioFormat.Audio16khz128kbitrateMonoM3;
    FLanguage := ELanguage.ptBR.ToString;
    FTextoVozFeminina := 'Voz Feminina %d';
    FTextoVozMasculina := 'Voz Masculina %d';

    // ...
    if not Assigned(FVozesFemininas) then
        FVozesFemininas := TListaVozes.Create;

    if not Assigned(FVozesMasculinas) then
        FVozesMasculinas := TListaVozes.Create;

    // ...
    FTokenPlayer := SolicitarToken;
end;

constructor TTextToSpeechAzure.Create(aToken, NewURLToken: String);
var
    NetHTTPClient: TNetHTTPClient;
    BodyStream: TStringStream;
begin
    FToken := aToken;
    FURLPegarToken := NewURLToken;
    FURLPedirNarracao := 'https://brazilsouth.tts.speech.microsoft.com/cognitiveservices/v1';
    FURLPedirListaVozes := 'https://brazilsouth.tts.speech.microsoft.com/cognitiveservices/voices/list';
    FFormatoAudio := EAudioFormat.Audio16khz128kbitrateMonoM3;
    FLanguage := ELanguage.ptBR.ToString;

    // ...
    FVozesFemininas := TListaVozes.Create;
    FVozesMasculinas := TListaVozes.Create;

    NetHTTPClient := TNetHTTPClient.Create(nil);
    try
        BodyStream := TStringStream.Create('[{"Content-Type": "application/json"}]', TEncoding.UTF8);
        NetHTTPClient.AcceptEncoding := c_UTF8;
        NetHTTPClient.ContentType := 'application/x-www-form-urlencoded';
        NetHTTPClient.CustHeaders.Add('Ocp-Apim-Subscription-Key', FToken);
        FTokenPlayer := NetHTTPClient.Post(FURLPegarToken, BodyStream).ContentAsString(TEncoding.UTF8);
    finally
        BodyStream.DisposeOf;
        NetHTTPClient.DisposeOf
    end;
end;

constructor TTextToSpeechAzure.Create(aToken, NewURLToken: String; NewURLService: String);
var
    NetHTTPClient: TNetHTTPClient;
    BodyStream: TStringStream;
begin
    FToken := aToken;
    FURLPegarToken := NewURLToken;
    FURLPedirNarracao := NewURLService;
    FURLPedirListaVozes := 'https://brazilsouth.tts.speech.microsoft.com/cognitiveservices/voices/list';
    FFormatoAudio := EAudioFormat.Audio16khz128kbitrateMonoM3;
    FLanguage := ELanguage.ptBR.ToString;

    // ...
    FVozesFemininas := TListaVozes.Create;
    FVozesMasculinas := TListaVozes.Create;

    NetHTTPClient := TNetHTTPClient.Create(nil);
    try
        BodyStream := TStringStream.Create('[{"Content-Type": "application/json"}]', TEncoding.UTF8);
        NetHTTPClient.AcceptEncoding := c_UTF8;
        NetHTTPClient.ContentType := 'application/x-www-form-urlencoded';
        NetHTTPClient.CustHeaders.Add('Ocp-Apim-Subscription-Key', FToken);
        FTokenPlayer := NetHTTPClient.Post(FURLPegarToken, BodyStream).ContentAsString(TEncoding.UTF8);
    finally
        BodyStream.DisposeOf;
        NetHTTPClient.DisposeOf
    end;
end;

destructor TTextToSpeechAzure.Destroy;
begin
    FVozesFemininas.Items.DisposeOf;
    FVozesFemininas.DisposeOf;
    FVozesMasculinas.Items.DisposeOf;
    FVozesMasculinas.DisposeOf;
  inherited;
end;

function TTextToSpeechAzure.GetListaVozes: TArray<TVoice>;
var
    NetHTTPClient: TNetHTTPClient;
    ResponseReqVoice: IHTTPResponse;
    ResponseJSONArray: TJSONArray;
    Voz: TVoice;
    I: Integer;
begin
    try
        // ... Faz a requisição da lista de vozes
        NetHTTPClient := TNetHTTPClient.Create(nil);
        try
            // ... Configura o componente de conexão
            NetHTTPClient.AcceptEncoding := c_UTF8;
            NetHTTPClient.ContentType := 'application/x-www-form-urlencoded';
            NetHTTPClient.CustHeaders.Add('Ocp-Apim-Subscription-Key', FToken);

            ResponseReqVoice := NetHTTPClient.Get(FURLPedirListaVozes);
            ResponseJSONArray := TJSONObject.ParseJSONValue(ResponseReqVoice.ContentAsString) as TJSONArray;

            // ... Limpa a lista de vozes para adicionar novas
            FVozesFemininas.Items.Clear;
            FVozesMasculinas.Items.Clear;

            // ... Filtra a lista de vozes
            for I := 0 to Pred(ResponseJSONArray.Size) do begin
                if ResponseJSONArray[I].FindValue('Locale').Value = FLanguage then begin
                    // ... Objeto para conter a voz
                    Voz.DisplayName := ResponseJSONArray[I].FindValue('DisplayName').Value;
                    Voz.ShortName := ResponseJSONArray[I].FindValue('ShortName').Value;
                    Voz.Gender := ResponseJSONArray[I].FindValue('Gender').Value;
                    Voz.VoiceType := ResponseJSONArray[I].FindValue('VoiceType').Value;
                    Voz.Status := ResponseJSONArray[I].FindValue('Status').Value;
                    Voz.Locale := ResponseJSONArray[I].FindValue('Locale').Value;

                    // ... Verifica o Gênero
                    if ResponseJSONArray[I].FindValue('Gender').Value = 'Male' then
                        begin
                            // ... Defini a voz de acordo com a variável TextVozMasculina
                            Voz.Name := Format(FTextoVozMasculina{'Voz Masculina %d'}, [FVozesMasculinas.FItems.Count +1]);
                            FVozesMasculinas.Items.Add(Voz);
                        end
                    else
                        begin
                            // ... Defini a voz de acordo com a variável TextVozFeminina
                            Voz.Name := Format(FTextoVozFeminina {'Voz Feminina %d'}, [FVozesFemininas.FItems.Count +1]);
                            FVozesFemininas.Items.Add(Voz);
                        end;
                end;
            end;

            // ... Retorna o TARRAY com todas as vozes
            Result := FVozesFemininas.FItems.ToArray + FVozesMasculinas.FItems.ToArray;
        finally
            ResponseJSONArray.DisposeOf;
            NetHTTPClient.DisposeOf;
        end;
    except on E: Exception do
        raise Exception.Create(E.Message);
    end;
end;

function TTextToSpeechAzure.GetListaVozes(aLanguage: String): TArray<TVoice>;
var
    NetHTTPClient: TNetHTTPClient;
    ResponseReqVoice: IHTTPResponse;
    ResponseJSONArray: TJSONArray;
    Voz: TVoice;
    I: Integer;
begin
    try
        // ... Atualiza o Idioma
        FLanguage := aLanguage;

        // ... Faz a requisição da lista de vozes
        NetHTTPClient := TNetHTTPClient.Create(nil);
        try
            // ... Configura o componente de conexão
            NetHTTPClient.AcceptEncoding := c_UTF8;
            NetHTTPClient.ContentType := 'application/x-www-form-urlencoded';
            NetHTTPClient.CustHeaders.Add('Ocp-Apim-Subscription-Key', FToken);

            ResponseReqVoice := NetHTTPClient.Get(FURLPedirListaVozes);
            ResponseJSONArray := TJSONObject.ParseJSONValue(ResponseReqVoice.ContentAsString) as TJSONArray;

            // ... Limpa a lista de vozes para adicionar novas
            FVozesFemininas.Items.Clear;
            FVozesMasculinas.Items.Clear;

            // ... Filtra a lista de vozes
            for I := 0 to Pred(ResponseJSONArray.Size) do begin
                if ResponseJSONArray[I].FindValue('Locale').Value = FLanguage then begin
                    // ... Objeto para conter a voz
                    Voz.DisplayName := ResponseJSONArray[I].FindValue('DisplayName').Value;
                    Voz.ShortName := ResponseJSONArray[I].FindValue('ShortName').Value;
                    Voz.Gender := ResponseJSONArray[I].FindValue('Gender').Value;
                    Voz.VoiceType := ResponseJSONArray[I].FindValue('VoiceType').Value;
                    Voz.Status := ResponseJSONArray[I].FindValue('Status').Value;
                    Voz.Locale := ResponseJSONArray[I].FindValue('Locale').Value;

                    // ... Verifica o Gênero
                    if ResponseJSONArray[I].FindValue('Gender').Value = 'Male' then
                        begin
                            // ... Defini a voz de acordo com a variável TextVozMasculina
                            Voz.Name := Format(FTextoVozMasculina{'Voz Masculina %d'}, [FVozesMasculinas.FItems.Count +1]);
                            FVozesMasculinas.Items.Add(Voz);
                        end
                    else
                        begin
                            // ... Defini a voz de acordo com a variável TextVozFeminina
                            Voz.Name := Format(FTextoVozFeminina {'Voz Feminina %d'}, [FVozesFemininas.FItems.Count +1]);
                            FVozesFemininas.Items.Add(Voz);
                        end;
                end;
            end;

            // ... Retorna o TARRAY com todas as vozes
            Result := FVozesFemininas.FItems.ToArray + FVozesMasculinas.FItems.ToArray;
        finally
            ResponseJSONArray.DisposeOf;
            NetHTTPClient.DisposeOf;
        end;
    except on E: Exception do
        raise Exception.Create(E.Message);
    end;
end;

function TTextToSpeechAzure.GetListaVozes(aLanguage: String; Gender: EGenero): TArray<TVoice>;
var
    NetHTTPClient: TNetHTTPClient;
    ResponseReqVoice: IHTTPResponse;
    ResponseJSONArray: TJSONArray;
    Voz: TVoice;
    I: Integer;
begin
    try
        // ... Atualiza o Idioma
        FLanguage := aLanguage;

        // ... Faz a requisição da lista de vozes
        NetHTTPClient := TNetHTTPClient.Create(nil);
        try
            // ... Configura o componente de conexão
            NetHTTPClient.AcceptEncoding := c_UTF8;
            NetHTTPClient.ContentType := 'application/x-www-form-urlencoded';
            NetHTTPClient.CustHeaders.Add('Ocp-Apim-Subscription-Key', FToken);

            // ...
            ResponseReqVoice := NetHTTPClient.Get(FURLPedirListaVozes);
            ResponseJSONArray := TJSONObject.ParseJSONValue(ResponseReqVoice.ContentAsString) as TJSONArray;

            // ... Limpa a lista de vozes para adicionar novas
            FVozesFemininas.Items.Clear;
            FVozesMasculinas.Items.Clear;

            // ... Filtra a lista de vozes
            for I := 0 to Pred(ResponseJSONArray.Size) do begin
                if (ResponseJSONArray[I].FindValue('Locale').Value = FLanguage) and (ResponseJSONArray[I].FindValue('Gender').Value = Gender.ToString) then begin
                    // ... Objeto para conter a voz
                    Voz.DisplayName := ResponseJSONArray[I].FindValue('DisplayName').Value;
                    Voz.ShortName := ResponseJSONArray[I].FindValue('ShortName').Value;
                    Voz.Gender := ResponseJSONArray[I].FindValue('Gender').Value;
                    Voz.VoiceType := ResponseJSONArray[I].FindValue('VoiceType').Value;
                    Voz.Status := ResponseJSONArray[I].FindValue('Status').Value;
                    Voz.Locale := ResponseJSONArray[I].FindValue('Locale').Value;

                    // ... Verifica o Gênero
                    if ResponseJSONArray[I].FindValue('Gender').Value = 'Male' then
                        begin
                            // ... Defini a voz de acordo com a variável TextVozMasculina
                            Voz.Name := Format(FTextoVozMasculina{'Voz Masculina %d'}, [FVozesMasculinas.FItems.Count +1]);
                            FVozesMasculinas.Items.Add(Voz);

                            // ... Retorna o TARRAY com as vozes Masculinas
                            Result := FVozesMasculinas.Items.ToArray;
                        end
                    else
                        begin
                            // ... Defini a voz de acordo com a variável TextVozFeminina
                            Voz.Name := Format(FTextoVozFeminina {'Voz Feminina %d'}, [FVozesFemininas.FItems.Count +1]);
                            FVozesFemininas.Items.Add(Voz);

                            // ... Retorna o TARRAY com as vozes Masculinas
                            Result := FVozesFemininas.Items.ToArray;
                        end;
                end;
            end;
        finally
            ResponseJSONArray.DisposeOf;
            NetHTTPClient.DisposeOf;
        end;
    except on E: Exception do
        raise Exception.Create(e.Message);
    end;
end;

function TTextToSpeechAzure.GetListaVozes(aLanguage: String; NewURLLista: String): TArray<TVoice>;
var
    NetHTTPClient: TNetHTTPClient;
    ResponseReqVoice: IHTTPResponse;
    ResponseJSONArray: TJSONArray;
    wArrayVoices: TArray<TVoice>;
    I: Integer;
begin
    try
        // ... Atualiza o Idioma
        FLanguage := aLanguage;

        // ... Faz a requisição da lista de vozes
        NetHTTPClient := TNetHTTPClient.Create(nil);
        try
            ResponseReqVoice := NetHTTPClient.Get(NewURLLista);
            ResponseJSONArray := TJSONObject.ParseJSONValue(ResponseReqVoice.ContentAsString) as TJSONArray;

            // ... Filtra a lista de vozes
            if Language = '' then
                begin
                    for I := 0 to Pred(ResponseJSONArray.Size) do begin
                        if ResponseJSONArray[I].FindValue('Locale').Value = Language then begin
                            SetLength(wArrayVoices, Length(wArrayVoices)+1);
                            wArrayVoices[Length(wArrayVoices)-1].Name := ResponseJSONArray[I].FindValue('Name').Value;

                            if ResponseJSONArray[I].FindValue('Gender').Value = 'Male' then
                                wArrayVoices[Length(wArrayVoices)-1].DisplayName := 'Voz Masculina ' + IntToStr(Length(wArrayVoices)-1)
                            else
                                wArrayVoices[Length(wArrayVoices)-1].DisplayName := 'Voz Feminina ' + IntToStr(Length(wArrayVoices)-1);

                            wArrayVoices[Length(wArrayVoices)-1].ShortName := ResponseJSONArray[I].FindValue('ShortName').Value;
                            wArrayVoices[Length(wArrayVoices)-1].Gender := ResponseJSONArray[I].FindValue('Gender').Value;
                            wArrayVoices[Length(wArrayVoices)-1].VoiceType := ResponseJSONArray[I].FindValue('VoiceType').Value;
                            wArrayVoices[Length(wArrayVoices)-1].Status := ResponseJSONArray[I].FindValue('Status').Value;
                        end;
                    end;
                end
            else
                begin
                    for I := 0 to Pred(ResponseJSONArray.Size) do begin
                        SetLength(wArrayVoices, Length(wArrayVoices)+1);
                        wArrayVoices[Length(wArrayVoices)-1].Name := ResponseJSONArray[I].FindValue('Name').Value;

                        if ResponseJSONArray[I].FindValue('Gender').Value = 'Male' then
                            wArrayVoices[Length(wArrayVoices)-1].DisplayName := 'Voz Masculina ' + IntToStr(Length(wArrayVoices)-1)
                        else
                            wArrayVoices[Length(wArrayVoices)-1].DisplayName := 'Voz Feminina ' + IntToStr(Length(wArrayVoices)-1);

                        wArrayVoices[Length(wArrayVoices)-1].ShortName := ResponseJSONArray[I].FindValue('ShortName').Value;
                        wArrayVoices[Length(wArrayVoices)-1].Gender := ResponseJSONArray[I].FindValue('Gender').Value;
                        wArrayVoices[Length(wArrayVoices)-1].VoiceType := ResponseJSONArray[I].FindValue('VoiceType').Value;
                        wArrayVoices[Length(wArrayVoices)-1].Status := ResponseJSONArray[I].FindValue('Status').Value;
                    end;
                end;

            // ... Retorna o TARRAY com as vozes
            Result := wArrayVoices;
        finally
            ResponseJSONArray.DisposeOf;
            NetHTTPClient.DisposeOf;
        end;
    except on E: Exception do
        raise Exception.Create(e.Message);
    end;
end;

function TTextToSpeechAzure.PegarNarracao(SSML: String; OutFormat: EAudioFormat): TMemoryStream;
var
    NetHTTPClient: TNetHTTPClient;
    HTTPResponse: IHTTPResponse;
    BodyStream: TStringStream;
    ResponseStream: TMemoryStream;
    Headers: TArray<TNameValuePair>;
    wTokenAcessoPlayer: String;
    wURL: String;
begin
    try
        // ... Preparando a TStream para enviar para o AZURE
        BodyStream := TStringStream.Create(SSML, TEncoding.UTF8);

        // ... Preparando a TStream com a resposta do AZURE
        ResponseStream := TMemoryStream.Create;

        NetHTTPClient := TNetHTTPClient.Create(nil);
        try
            // ... Configuração do Componente NetHTTPClient
            with NetHTTPClient do begin
                Accept := 'application/json, text/plain; q=0.9, text/html;q=0.8,';
                AcceptEncoding := c_UTF8;
                ContentType := 'application/ssml+xml; charset=UTF-8';
                AcceptCharSet := c_UTF8;
                AcceptLanguage := 'pt-br, en;q=0.9,*;q=0.8';
                HandleRedirects := True;
            end;

            // ... Cabelho HTTP da requisição
            Headers := TNetHeaders.Create(
                TNameValuePair.Create('Ocp-Apim-Subscription-Key', FToken),
                TNameValuePair.Create('Authorization', 'Bearer-'+ FTokenPlayer),
                TNameValuePair.Create('X-Microsoft-OutputFormat', OutFormat.ToString),
                TNameValuePair.Create('Content-Length', BodyStream.Size.ToString),
                TNameValuePair.Create('User-Agent','radiopro-speech')
            );

            // ... Endereço da requisição
            FURLPedirNarracao := 'https://brazilsouth.tts.speech.microsoft.com/cognitiveservices/v1';
            HTTPResponse := NetHTTPClient.Post(FURLPedirNarracao, BodyStream, ResponseStream, Headers);

            if HTTPResponse.StatusCode = 200 then
                Result := ResponseStream
            else
                Result := nil;
        finally
            BodyStream.DisposeOf;
            //ResponseStream.DisposeOf; //Não pode liberar memória antes de salvar
            NetHTTPClient.DisposeOf;
        end;
    except on E: Exception do
        raise Exception.Create(e.Message);
    end;
end;

{ EAudioFormatHelper }

function EAudioFormatHelper.ToString: String;
begin
    case Self of
        EAudioFormat.AMRWB16000hz: Result := 'amr-wb-16000hz';
        EAudioFormat.Audio16khz16bit32kbpsMonoOpus: Result := 'audio-16khz-16bit-32kbps-mono-opus';
        EAudioFormat.Audio16khz32kbitrateMonoMP3: Result := 'audio-16khz-32kbitrate-mono-mp3';
        EAudioFormat.Audio16khz64kbitrateMonoMP3: Result := 'audio-16khz-64kbitrate-mono-mp3';
        EAudioFormat.Audio16khz128kbitrateMonoM3: Result := 'audio-16khz-128kbitrate-mono-mp3';
        EAudioFormat.Audio24khz16bit24kbpsMonoOpus: Result := 'audio-24khz-16bit-24kbps-mono-opus';
        EAudioFormat.Audio24khz16bit48kbpsMonoOpus: Result := 'audio-24khz-16bit-48kbps-mono-opus';
        EAudioFormat.Audio24khz48kbitrateMonoMP3: Result := 'audio-24khz-48kbitrate-mono-mp3';
        EAudioFormat.Audio24khz96kbitrateMonoMP3: Result := 'audio-24khz-96kbitrate-mono-mp3';
        EAudioFormat.Audio24khz160kbitrateMonoMP3: Result := 'audio-24khz-160kbitrate-mono-mp3';
        EAudioFormat.Audio48khz96kbitrateMonoMP3: Result := 'audio-48khz-96kbitrate-mono-mp3';
        EAudioFormat.Audio48khz192kbitrateMonoMP3: Result := 'audio-48khz-192kbitrate-mono-mp3';
        EAudioFormat.Ogg16khz16bitMonoOpus: Result := 'ogg-16khz-16bit-mono-opus';
        EAudioFormat.Ogg24khz16bitMonoOpus: Result := 'ogg-24khz-16bit-mono-opus';
        EAudioFormat.Ogg48khz16bitMonoOpus: Result := 'ogg-48khz-16bit-mono-opus';
        EAudioFormat.Oaw8khz8bitMonoLaw: Result := 'raw-8khz-8bit-mono-alaw';
        EAudioFormat.Raw8khz8bitMonoMulaw: Result := 'raw-8khz-8bit-mono-mulaw';
        EAudioFormat.Raw8khz16bitMonoPCM: Result := 'raw-8khz-16bit-mono-pcm';
        EAudioFormat.Raw16khz16bitMonoPCM: Result := 'raw-16khz-16bit-mono-pcm';
        EAudioFormat.Raw16khz16bitMonoTruesilk: Result := 'raw-16khz-16bit-mono-truesilk';
        EAudioFormat.Raw22050hz16bitMonoPCM: Result := 'raw-22050hz-16bit-mono-pcm';
        EAudioFormat.Raw24khz16bitMonoPCM: Result := 'raw-24khz-16bit-mono-pcm';
        EAudioFormat.Raw24khz16bitMonoTruesilk: Result := 'raw-24khz-16bit-mono-truesilk';
        EAudioFormat.Raw44100hz16bitMonoPCM: Result := 'raw-44100hz-16bit-mono-pcm';
        EAudioFormat.Raw48khz16bitMonoPCM: Result := 'raw-48khz-16bit-mono-pcm';
        EAudioFormat.Webm16khz16bitMonoOpus: Result := 'webm-16khz-16bit-mono-opus';
        EAudioFormat.Webm24khz16bit24kbpsMonoOpus: Result := 'webm-24khz-16bit-24kbps-mono-opus';
        EAudioFormat.Webm24khz16bitMonoOpus: Result := 'webm-24khz-16bit-mono-opus';
        EAudioFormat.Riff8khz8bitMonoAlaw: Result := 'riff-8khz-8bit-mono-alaw';
        EAudioFormat.Riff8khz8bitMonoMulaw: Result := 'riff-8khz-8bit-mono-mulaw';
        EAudioFormat.Riff8khz16bitMonoPCM: Result := 'riff-8khz-16bit-mono-pcm';
        EAudioFormat.Riff22050hz16bitMonoPCM: Result := 'riff-22050hz-16bit-mono-pcm';
        EAudioFormat.Riff24khz16bitMonoPCM: Result := 'riff-24khz-16bit-mono-pcm';
        EAudioFormat.Riff44100hz16bitMonoPCM: Result := 'riff-44100hz-16bit-mono-pcm';
        EAudioFormat.Riff48khz16bitMonoPCM: Result := 'riff-48khz-16bit-mono-pcm';
    end;
end;

{ EGeneroHelper }

function EGeneroHelper.ToString: String;
begin
    case Self of
        EGenero.Male: Result := 'Male';
        EGenero.Female: Result := 'Female';
    end;
end;

function EGeneroHelper.ToTexto: String;
begin
    case Self of
        EGenero.Male: Result := 'Masculina';
        EGenero.Female: Result := 'Feminina';
    end;
end;

{ EVoiceStyleHelper }

function EVoiceStyleHelper.ToString: String;
begin
    case Self of
        EVoiceStyle.AdvertisementUpbeat: Result := 'advertisement_upbeat';
        EVoiceStyle.Affectionate: Result := 'affectionate';
        EVoiceStyle.Angry: Result := 'angry';
        EVoiceStyle.Assistant: Result := 'assistant';
        EVoiceStyle.Calm: Result := 'calm';
        EVoiceStyle.Chat: Result := 'chat';
        EVoiceStyle.Cheerful: Result := 'cheerful';
        EVoiceStyle.Customerservice: Result := 'customerservice';
        EVoiceStyle.Depressed: Result := 'depressed';
        EVoiceStyle.Disgruntled: Result := 'disgruntled';
        EVoiceStyle.DocumentaryNarration: Result := 'documentary-narration';
        EVoiceStyle.Embarrassed: Result := 'embarrassed';
        EVoiceStyle.Empathetic: Result := 'empathetic';
        EVoiceStyle.Envious: Result := 'envious';
        EVoiceStyle.Excited: Result := 'excited';
        EVoiceStyle.Fearful: Result := 'fearful';
        EVoiceStyle.Friendly: Result := 'friendly';
        EVoiceStyle.Gentle: Result := 'gentle';
        EVoiceStyle.Hopeful: Result := 'hopeful';
        EVoiceStyle.Lyrical: Result := 'lyrical';
        EVoiceStyle.NarrationProfessional: Result := 'narration-professional';
        EVoiceStyle.NarrationRelaxed: Result := 'narration-relaxed';
        EVoiceStyle.Newscast: Result := 'newscast';
        EVoiceStyle.NewscastCasual: Result := 'newscast-casual';
        EVoiceStyle.NewscastFormal: Result := 'newscast-formal';
        EVoiceStyle.PoetryReading: Result := 'poetry-reading';
        EVoiceStyle.Sad: Result := 'sad';
        EVoiceStyle.Serious: Result := 'serious';
        EVoiceStyle.Shouting: Result := 'shouting';
        EVoiceStyle.SportsCommentary: Result := 'sports_commentary';
        EVoiceStyle.SportsCommentaryExcited: Result := 'sports_commentary_excited';
        EVoiceStyle.Whispering: Result := 'whispering';
        EVoiceStyle.Terrified: Result := 'terrified';
        EVoiceStyle.Unfriendly: Result := 'unfriendly';
    end;
end;

function EVoiceStyleHelper.ToTexto: String;
begin
    case Self of
        EVoiceStyle.AdvertisementUpbeat: Result := 'Otimista';
        EVoiceStyle.Affectionate: Result := 'Afetuoso';
        EVoiceStyle.Angry: Result := 'Nervoso';
        EVoiceStyle.Assistant: Result := 'Assistente';
        EVoiceStyle.Calm: Result := 'Calmo';
        EVoiceStyle.Chat: Result := 'Bate papo';
        EVoiceStyle.Cheerful: Result := 'Alegre';
        EVoiceStyle.Customerservice: Result := 'Atendimento ao Cliente';
        EVoiceStyle.Depressed: Result := 'Depressivo';
        EVoiceStyle.Disgruntled: Result := 'Desapontado';
        EVoiceStyle.DocumentaryNarration: Result := 'Documentário Narração';
        EVoiceStyle.Embarrassed: Result := 'Envergonhado';
        EVoiceStyle.Empathetic: Result := 'Empático';
        EVoiceStyle.Envious: Result := 'Invejoso';
        EVoiceStyle.Excited: Result := 'Excitado';
        EVoiceStyle.Fearful: Result := 'Medroso';
        EVoiceStyle.Friendly: Result := 'Amigável';
        EVoiceStyle.Gentle: Result := 'Gentil';
        EVoiceStyle.Hopeful: Result := 'Esperançoso';
        EVoiceStyle.Lyrical: Result := 'Lírico';
        EVoiceStyle.NarrationProfessional: Result := 'Narração Profissional';
        EVoiceStyle.NarrationRelaxed: Result := 'Narração Relaxado';
        EVoiceStyle.Newscast: Result := 'Noticiário';
        EVoiceStyle.NewscastCasual: Result := 'Noticiário Casual';
        EVoiceStyle.NewscastFormal: Result := 'Noticiário Formal';
        EVoiceStyle.PoetryReading: Result := 'Leitura de poesia';
        EVoiceStyle.Sad: Result := 'Triste';
        EVoiceStyle.Serious: Result := 'Sério';
        EVoiceStyle.Shouting: Result := 'Gritando';
        EVoiceStyle.SportsCommentary: Result := 'Comentário esportivo';
        EVoiceStyle.SportsCommentaryExcited: Result := 'Comentário Esportivo Animado';
        EVoiceStyle.Whispering: Result := 'Sussurrando';
        EVoiceStyle.Terrified: Result := 'Aterrorizado';
        EVoiceStyle.Unfriendly: Result := 'Hostil';
    end;
end;

{ ERateVozHelper }

function ERateVozHelper.ToString: String;
begin
    case Self of
        ERateVoz.xSlow: Result := 'x-slow';
        ERateVoz.Slow: Result := 'slow';
        ERateVoz.Medium: Result := 'medium';
        ERateVoz.Fast: Result := 'fast';
        ERateVoz.xFast: Result := 'x-fast';
        ERateVoz.Default: Result := 'default';
    end;
end;

{ ELanguageHelper }

function ELanguageHelper.ToString: String;
begin
    case Self of
        ELanguage.ptBR: Result := 'pt-BR';
        ELanguage.enUS: Result := 'en-US';
        ELanguage.esES: Result := 'es-ES';
        ELanguage.zhCN: Result := 'zh-CN';
        ELanguage.bnBD: Result := 'bn-BD';
        ELanguage.ruRU: Result := 'ru-RU';
        ELanguage.jaJP: Result := 'ja-JP';
        ELanguage.paIN: Result := 'pa-IN';

    end;
end;

function ELanguageHelper.ToTexto: String;
begin
    case Self of
        ELanguage.ptBR: Result := 'Português (Brasil)';
        ELanguage.enUS: Result := 'Inglês (Estados Unidos)';
        ELanguage.esES: Result := 'Espanhol (Espanha)';
        ELanguage.zhCN: Result := 'Chinês (China)';
        ELanguage.bnBD: Result := 'Bengali (Bangladesh)';
        ELanguage.ruRU: Result := 'Russo (Rússia)';
        ELanguage.jaJP: Result := 'Japonês (Japão)';
        ELanguage.paIN: Result := 'Punjabi (Índia)';
    end;
end;

{ EPitchHelper }

function EPitchHelper.ToString: String;
begin
    case Self of
        EPitch.xlow: Result := 'x-low';
        EPitch.low: Result := 'low' ;
        EPitch.medium: Result := 'medium';
        EPitch.high: Result := 'high';
        EPitch.xhigh: Result := 'x-high';
        EPitch.default: Result := 'default';
    end;
end;

{ EVolumeHelper }

function EVolumeHelper.ToString: String;
begin
    case Self of
        EVolume.silent: Result := 'silent';
        EVolume.xSoft: Result := 'x-soft';
        EVolume.soft: Result := 'soft';
        EVolume.medium: Result := 'medium';
        EVolume.loud: Result := 'loud';
        EVolume.xLoud: Result := 'x-loud';
        EVolume.default: Result := 'default';
    end;
end;

{ TVozesMasculinas }

constructor TListaVozes.Create;
begin
    FItems := TList<TVoice>.Create;
end;

destructor TListaVozes.Destroy;
begin
    FItems.DisposeOf;
  inherited;
end;

function TListaVozes.listName: TArray<String>;
var
    I: Integer;
begin
    for I := 0 to Pred(Self.FItems.Count) do begin
        Result := Result + [FItems[I].Name];
    end;
end;

procedure TListaVozes.SetItems(const Value: TList<TVoice>);
begin
    if Assigned(FItems) then
        FItems := Value;
end;

end.
