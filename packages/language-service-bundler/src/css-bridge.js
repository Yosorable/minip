const cssService = require('vscode-css-languageservice');
const { TextDocument } = require('vscode-languageserver-textdocument');

const ls = cssService.getCSSLanguageService();

globalThis.CSSLanguageService = {
  doComplete: function(uri, text, line, character) {
    try {
      const doc = TextDocument.create(uri, 'css', 1, text);
      const pos = { line: line, character: character };
      const stylesheet = ls.parseStylesheet(doc);
      const result = ls.doComplete(doc, pos, stylesheet);
      return JSON.stringify(result);
    } catch (e) {
      return JSON.stringify({ isIncomplete: false, items: [] });
    }
  },

  doHover: function(uri, text, line, character) {
    try {
      const doc = TextDocument.create(uri, 'css', 1, text);
      const pos = { line: line, character: character };
      const stylesheet = ls.parseStylesheet(doc);
      const result = ls.doHover(doc, pos, stylesheet);
      return JSON.stringify(result || null);
    } catch (e) {
      return JSON.stringify(null);
    }
  },

  doValidation: function(uri, text) {
    try {
      const doc = TextDocument.create(uri, 'css', 1, text);
      const stylesheet = ls.parseStylesheet(doc);
      const diagnostics = ls.doValidation(doc, stylesheet);
      return JSON.stringify(diagnostics);
    } catch (e) {
      return JSON.stringify([]);
    }
  }
};
