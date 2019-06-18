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
    }

type Route
    = LoginRoute
    | ProfileRoute
    | RegisterRoute
    | UsersRoute

initialModel : Model
initialModel =
    Model ProfileRoute emptyLoginPageData emptyRegisterPageData emptyUsersPageData

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
    | GotRegisterUserResponse (Result Http.Error String) -- String=status true if successfully added

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of

        ShowHomePage ->
            ( { model | route = LoginRoute }, Cmd.none )

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
                    ( { model | registerPageData = { usernameInput = "Failed to add new user!", passwordInput = model.registerPageData.passwordInput }}, Cmd.none )

                Ok status ->
                    ( { model | registerPageData = { usernameInput = "Added new user, Status: " ++ status, passwordInput = model.registerPageData.passwordInput }}, Cmd.none )

        TryLogin ->
            ( model, tryLoginCmd )
            


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

tryLoginCmd : Cmd msg
tryLoginCmd =
    Cmd.none



-- DECODERS & ENCODERS

statusDecoder : Json.Decode.Decoder String
statusDecoder =
    Json.Decode.field "status" Json.Decode.string

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
            
    in
    div []
        [ headerView
        , div [class "container"]
            [ vw
            , footerView
            ]
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