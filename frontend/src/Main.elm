module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode
import Json.Encode
import RemoteData exposing (WebData)



-- MAIN

main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- INIT

init : () -> ( Model, Cmd msg )
init flags = 
    ( initialModel, Cmd.none )



-- MODEL

type alias Model =
    { route: Route
    , loginPageData: LoginPageData
    , registerPageData: RegisterPageData
    , usersPageData: UsersPageData
    , jwtToken: Maybe String
    , bottomUserMessage: String
    }

type Route
    = LoginRoute
    | ProfileRoute
    | RegisterRoute
    | UsersRoute
    | HomeRoute

initialModel : Model
initialModel =
    Model LoginRoute emptyLoginPageData emptyRegisterPageData emptyUsersPageData Nothing ""

type alias LoginPageData =
    { usernameInput: String
    , passwordInput: String
    }

emptyLoginPageData : LoginPageData
emptyLoginPageData =
    LoginPageData "" ""

type alias RegisterPageData =
    { usernameInput: String
    , passwordInput: String
    }

emptyRegisterPageData : RegisterPageData
emptyRegisterPageData =
    RegisterPageData "" ""

type alias User =
    { username: String
    , pw_hash: String
    , pw_salt: String
    }

type alias UsersPageData =
    { users: WebData (List User)
    }

emptyUsersPageData : UsersPageData
emptyUsersPageData =
    UsersPageData RemoteData.NotAsked

type alias NewUser =
    { username: String
    , password: String
    }



-- UDPATE

type Msg
    = ShowLoginPage
    | ShowRegisterPage
    | ShowProfilePage
    | ShowHomePage
    | ChangeLoginUsernameInput String
    | ChangeLoginPasswordInput String
    | ChangeRegisterUsernameInput String
    | ChangeRegisterPasswordInput String
    | RegisterUser
    | TryLogin
    | GotRegisterUserResponse (Result Http.Error Bool) -- Bool=status true if successfully added
    | GotTryLoginResponse (Result Http.Error TryLoginResponse)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of

        ShowHomePage ->
            case model.jwtToken of
                Nothing ->
                    ( { model | route = LoginRoute }, Cmd.none )

                Just _ ->
                    ( { model | route = HomeRoute }, Cmd.none )

        ShowLoginPage ->
            ( { model | route = LoginRoute }, Cmd.none )

        ShowRegisterPage ->
            ( { model | route = RegisterRoute }, Cmd.none )

        ShowProfilePage ->
            ( { model | route = ProfileRoute }, Cmd.none )

        ChangeLoginUsernameInput str ->
            ( { model | loginPageData = { usernameInput = str, passwordInput = model.loginPageData.passwordInput }}, Cmd.none )

        ChangeLoginPasswordInput str ->
            ( { model | loginPageData = { usernameInput = model.loginPageData.usernameInput, passwordInput = str }}, Cmd.none )

        ChangeRegisterUsernameInput str ->
            ( { model | registerPageData = { usernameInput = str, passwordInput = model.registerPageData.passwordInput }}, Cmd.none )

        ChangeRegisterPasswordInput str ->
            ( { model | registerPageData = { usernameInput = model.registerPageData.usernameInput, passwordInput = str }}, Cmd.none )

        RegisterUser ->
            ( model, registerUserCmd (NewUser model.registerPageData.usernameInput model.registerPageData.passwordInput))

        GotRegisterUserResponse result ->
            case result of
                Err error ->
                    ( { model | bottomUserMessage = "Failed to add new user! Error: " ++ httpErrorToString error }
                    , Cmd.none )

                Ok status ->
                    ( { model
                        | bottomUserMessage = "Added new user, Status: " ++ if status then "true" else "false"
                        , loginPageData = { usernameInput = model.registerPageData.usernameInput, passwordInput = model.registerPageData.passwordInput }
                        , route = LoginRoute
                      }
                    , tryLoginCmd (NewUser model.registerPageData.usernameInput model.registerPageData.passwordInput) )

        TryLogin ->
            ( model, tryLoginCmd (NewUser model.loginPageData.usernameInput model.loginPageData.passwordInput))

        GotTryLoginResponse result ->
            case result of
                Err error ->
                    ( { model | bottomUserMessage = "Failed to login! Error: " ++ httpErrorToString error }
                    , Cmd.none )
                    
                Ok response ->
                    if response.status then
                        ( { model
                            | bottomUserMessage = "Logged in!" 
                            , jwtToken = Just response.jwttoken
                            , route = HomeRoute
                          }
                        , Cmd.none )
                    else
                        ( { model
                            | bottomUserMessage = "Authentication failed!" 
                            , jwtToken = Nothing
                          }
                        , Cmd.none )
            


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none 



-- COMMANDS

urlPathToApi : String
urlPathToApi =
    "http://0.0.0.0:8181/api/v1/"

registerUserCmd : NewUser -> Cmd Msg
registerUserCmd user =
    let
        body =
            newUserEncoder user
                |> Http.jsonBody

        url =
            (urlPathToApi ++ "users")

        expect = Http.expectJson GotRegisterUserResponse statusDecoder

    in
    Http.post
        { url = url
        , body = body
        , expect = expect
        }

tryLoginCmd : NewUser -> Cmd Msg
tryLoginCmd user =
    let
        body =
            newUserEncoder user
                |> Http.jsonBody

        url =
            (urlPathToApi ++ "login")

        expect = Http.expectJson GotTryLoginResponse loginResponseDecoder
            
    in
    Http.post
        { url = url
        , body = body
        , expect = expect
        }

httpErrorToString : Http.Error -> String
httpErrorToString httpError =
    case httpError of
      Http.BadUrl _ ->
        "Bad Url (did not provide a valid URL)"

      Http.Timeout ->
        "TimeoutError (took too long to get a response)"

      Http.NetworkError ->
        "NetworkError"

      Http.BadStatus _ ->
        "Bad Status (got a response back but status code indicates failure)"

      Http.BadBody str ->
        "Bad Body (body of response was smth. unexpected) " ++ str



-- DECODERS & ENCODERS

statusDecoder : Json.Decode.Decoder Bool
statusDecoder =
    Json.Decode.field "status" Json.Decode.bool

type alias TryLoginResponse =
    { jwttoken : String
    , status : Bool
    }

loginResponseDecoder : Json.Decode.Decoder TryLoginResponse
loginResponseDecoder =
    Json.Decode.map2 TryLoginResponse
        (Json.Decode.field "result" Json.Decode.string)
        (Json.Decode.field "status" Json.Decode.bool)

newUserEncoder : NewUser -> Json.Encode.Value
newUserEncoder user =
    Json.Encode.object
        [ ( "username", Json.Encode.string user.username )
        , ( "password", Json.Encode.string user.password )
        ]


-- VIEW

view : Model -> Html Msg
view model =
    let
        vw = 
            case model.route of
                LoginRoute ->
                    loginView model.loginPageData

                ProfileRoute ->
                    profileView

                RegisterRoute ->
                    registerView model.registerPageData

                UsersRoute ->
                    usersView model.usersPageData

                HomeRoute ->
                    homeView model
            
    in
    div []
        [ headerView
        , div [class "container"]
            [ vw
            , bottomUserMessageView model.bottomUserMessage
            , footerView
            ]
        ]

bottomUserMessageView : String -> Html Msg
bottomUserMessageView bottomUserMessage =
    div []
        [ h3 []
            [ text "User Message:" ]
        , text bottomUserMessage
        ]

headerView : Html Msg
headerView =
    div [ class "d-flex flex-column flex-md-row align-items-center p-3 px-md-4 mb-3 bg-dark border-bottom shadow-sm" ]
        [ a [ onClick ShowHomePage, class "my-0 mr-md-auto font-weight-normal text-white" ]
            [ h5 [ class "my-0 mr-md-auto font-weight-normal" ]
                [ text "Secure UserManagement" ]
            ]
        , nav [ class "my-2 my-md-0 mr-md-3" ]
            [ a [ onClick ShowLoginPage, class "p-2 text-white" ]
                [ text "Anmelden" ]
            , a [ onClick ShowRegisterPage, class "p-2 text-white" ]
                [ text "Registrieren" ]
            ]
        ]

footerView : Html Msg
footerView =
    footer [ class "pt-4 my-md-5 pt-md-5 border-top" ]
        [ div [ class "row" ]
            [ div [ class "col-12 col-md" ]
                [ small [ class "d-block mb-3 text-muted" ]
                    [ text "©", text "2019 Dominik Rosser" ]
                ]
            ]
        ]

loginView : LoginPageData -> Html Msg
loginView data =
    div []
        [ h2 []
            [ text "Login" ]
        , div [ class "row" ]
            [ div [ class "col-md-8" ]
                [ section [ id "loginForm" ]
                    [ div [] -- we use div instead of: Html.form [ method "POST", action "---" ]
                        [
                            -- Username Input
                            div [ class "form-group" ]
                                [ label [ for "inputUsername", class "col-md-2 control-label" ]
                                    [ text "Benutzername:" ]
                                , div [ class "col-md-10" ]
                                    [ input [ type_ "text", name "username", id "inputUsername", class "form-control"
                                            , value data.usernameInput, onInput ChangeLoginUsernameInput ]
                                            []
                                    ]
                                ]
                            -- Password Input
                            , div [ class "form-group" ]
                                [ label [ for "inputPassword", class "col-md-2 control-label" ]
                                    [ text "Passwort:" ]
                                , div [ class "col-md-10" ]
                                    [ input [ type_ "password", name "Password", id "inputPassword", class "form-control"
                                            , value data.passwordInput, onInput ChangeLoginPasswordInput ]
                                            []
                                    ]
                                ]
                            -- Submit Button
                            , div [ class "form-group" ]
                                [ div [ class "col-md-offset-2 col-md-10" ]
                                    [ input [ type_ "submit", value "Anmelden", class "btn btn-primary"
                                            , onClick TryLogin
                                            ]
                                            []
                                    ]
                                ]
                        ]
                    ]
                ]
            ]
        ]

profileView : Html Msg 
profileView =
    div []
        [ h2 []
            [ text "Profil" ]
        , div []
            [ dl [ class "dl-horizontal" ]
                [ dt [] [ text "Username:" ]
                , dd [] [ text "dummyusername" ]
                ]
            ]
        ]

registerView : RegisterPageData -> Html Msg
registerView data =
    div []
        [ h2 []
            [ text "Registrieren" ]
        , div [ class "row" ]
            [ div [ class "col-md-8" ]
                [ section [ id "loginForm" ]
                    [ div[] -- we use div instead of: Html.form [ method "POST", action "---" ]

                        -- Username
                        [ div [ class "form-group" ]
                            [ label [ for "inputUsername", class "col-md-4 control-label" ]
                                [ text "Benutzername:" ]
                            , div [ class "col-md-10" ]
                                [ input [ type_ "text", name "username", id "inputUsername", class "form-control"
                                        , value data.usernameInput, onInput ChangeRegisterUsernameInput ]
                                        []
                                ]
                            ]

                        -- Password
                        , div [ class "form-group" ]
                            [ label [ for "inputPassword", class "col-md-4 control-label" ]
                                [ text "Passwort" ]
                            , div [ class "col-md-10" ]
                                [ input [ type_ "password", name "Password", id "inputPassword", class "form-control"
                                        , value data.passwordInput, onInput ChangeRegisterPasswordInput ]
                                        []
                                ]
                            ]

                        -- Password repeat
                        , div [ class "form-group" ]
                            [ label [ for "inputPasswordRepeat", class "col-md-4 control-label" ]
                                [ text "Passwort wiederholen" ]
                            , div [ class "col-md-10" ]
                                [ input [ type_ "password", name "PasswordRepeat", id "inputPasswordRepeat", class "form-control"
                                        , value data.passwordInput, onInput ChangeRegisterPasswordInput ]
                                        []
                                ]
                            ]

                        -- Submit register button
                        , div [ class "form-group" ]
                            [ div [ class "col-md-offset-2 col-md-10" ]
                                [ input [ type_ "submit", value "Registrieren", class "btn btn-primary"
                                        , onClick RegisterUser ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

usersView : UsersPageData -> Html Msg
usersView data =
    text "Users - TODO"

homeView : Model -> Html Msg
homeView model =
    div []
        [ h2 []
            [ text "Home" ]
        , jwttokenView model.jwtToken
        ]

jwttokenView : Maybe String -> Html Msg
jwttokenView jwttoken =
    let
        displayToken =
            case jwttoken of
                Just token ->
                    token
                    
                Nothing ->
                    "No valid jwt token"
    in
    
    div []
        [ h3 []
            [ text "Jwt Token: "]
        , text displayToken
        ]