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

import OktaAuth from '@okta/okta-auth-js/jquery';

import loginRedirect from './login-redirect';
import logout from './logout';

const Elm = require('./Main.elm');

export function bootstrap(config) {

  const auth = new OktaAuth({
    url: config.oktaUrl,
    issuer: config.oktaUrl, // <------- works! but sounds right?
    clientId: config.clientId,
    redirectUri: config.redirectUri,
    authorizeUrl: `${config.oktaUrl}${config.authzUrl}`,
    scopes: ['openid', 'profile:read', 'usage:read'],
  });

  const hashes = (window.location.hash.substr(1)).split('&') || [];
  const hashObj = hashes.reduce((init, x) => {
    const xs = x.split('=');
    let key = xs[0];
    const val = xs[1];
    return Object.assign({}, init, {[key]: val});
  }, {});

  console.log(hashObj);

  const containerEl = document.querySelector(config.container);
  const app = Elm.Main.embed(containerEl, {
    tokenResp: {
      accessToken: hashObj['access_token'],
      idToken: hashObj['id_token'],
      scope: hashObj['scope'].split('+'),
    }
  });

  app.ports.loginRedirect.subscribe(() => {
    loginRedirect(auth);
  });

  app.ports.logout.subscribe(() => {
    logout(auth);
  });
}

export default bootstrap;
