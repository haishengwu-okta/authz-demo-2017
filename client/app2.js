/*!
 * Copyright (c) 2015-2016, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import OktaAuth from '@okta/okta-auth-js/';
import * as R from 'ramda';
import Elm from './app2/Main.elm';
import './app2/main.css';

export function bootstrap (config) {
  let baseUrl;
  let authzUrl;
  let issuer;
  if (config.asId) {
    issuer = `${config.oktaUrl}/oauth2/${config.asId}`;
    baseUrl = `${config.oktaUrl}/oauth2/${config.asId}/v1`;
    authzUrl = `${baseUrl}/authorize`;
  } else {
    issuer = config.oktaUrl;
    baseUrl = `${config.oktaUrl}/oauth2/v1`;
    authzUrl = `${baseUrl}/authorize`;
  }

  // init auth sdk
  const auth = new OktaAuth({
    url: config.oktaUrl,
    issuer: issuer,
    clientId: config.clientId,
    redirectUri: config.redirectUri,
    authorizeUrl: authzUrl,
  });

  function redirectFormPost (auth) {
    auth.token.getWithRedirect({
      responseType: [
        'token',
        'id_token',
      ],
      scopes: [
        'openid',
        'profile',
      ],
      responseMode: 'form_post',
      prompt: 'consent',
    });
  }

  function redirectFragment (auth) {
    auth.token.getWithRedirect({
      responseType: [
        'token',
        'id_token',
      ],
      scopes: [
        'openid',
        'profile',
      ],
      prompt: 'consent',
    });
  }

  function redirectCodeFlow (auth) {
    auth.token.getWithRedirect({
      responseType: [
        'code',
      ],
      scopes: [
        'openid',
        'profile',
      ],
      // prompt: 'consent',
    });
  }

  function popupOktaPostMessage (auth) {
    auth.token.getWithPopup({
      responseType: ['token', 'id_token', ],
      scopes: ['openid', 'profile', ],
      // responseMode: 'okta_post_message', default response mode when `getWithPopup`
      // responseMode: 'fragment',
    })
      .done((resps) => {
        const resp = resps.filter((r) => !!r.idToken)[0];
        console.log(resps);

        if (resp) {
          renderView(resp.idToken);
        }
      });
  }

  const authFns = {
    redirectCodeFlow,
    redirectFragment,
    popupOktaPostMessage,
    redirectFormPost,
  };

  const renderView = (idTokenRaw = null) => {
    // render main view
    const containerEl = document.querySelector(config.container);

    let idToken = null;
    if (idTokenRaw) {
      const decodedIdToken = auth.token.decode(idTokenRaw).payload;
      const displayLabelOfIdToken = R.pick(['iss', 'name', 'org', 'preferred_username']);
      idToken = R.merge({
        idTokenRaw,
        org: null,
      }, displayLabelOfIdToken(decodedIdToken));
    }

    const app = Elm.Main.embed(containerEl, {
      oidcConfig: {
        oidcBaseUrl: baseUrl,
        redirectUri: config.redirectUri,
        idToken,
      },
    });

    // Elm -> JS
    app.ports.invokeAuthFn.subscribe((fnName) => {
      const fn = authFns[fnName];
      if (!fn) {
        console.error(`cannot find auth handler for ${fnName}`);
      }
      fn(auth);
    });
  };

  if (config.idToken) {
    renderView(config.idToken);
  } else {
    auth.token.parseFromUrl()
      .then((token = []) => {
        const idTokenResp = token.filter((t) => !!t.idToken);
        if (!idTokenResp.length) {
          renderView();
        } else {
          renderView(idTokenResp[0].idToken);
        }
      })
      .catch(() => renderView());
  }
}

export default bootstrap;
