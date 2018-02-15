for (let key in ExScript.Modules) {
  if (key.match(/^ExScriptStdlib/)) {
    const modName = key.replace('ExScriptStdlib', '')
    ExScript.Modules[modName] = ExScript.Modules[key]
  }
}
