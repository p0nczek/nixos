nn() {
  local msg="$1"
  [[ -z "$msg" ]] && { echo "nn: podaj opis. Użycie: nn \"opis zmiany\""; return 1; }
  cd /etc/nixos || return 1
  git add -N . 2>/dev/null || true
  jj commit -m "$msg" 2> /tmp/jj.err
  local jj_exit=$?
  if [[ $jj_exit -ne 0 ]]; then
    if grep -q "Refusing to move bookmark" /tmp/jj.err 2>/dev/null; then
      local bm
      bm=$(jj bookmark list --revision @- --template 'name ++ "\n"' 2>/dev/null | head -n1)
      [[ -n "$bm" ]] && jj bookmark move "$bm" --to @- --allow-backwards 2>/dev/null
    elif grep -q "no author and/or committer set" /tmp/jj.err 2>/dev/null; then
      echo "⚠️  jj: ustaw autora: git config user.name \"shin\"; git config user.email \"shin@nixos\""
    else
      cat /tmp/jj.err
      return 1
    fi
  fi
  NIXOS_LABEL="$msg" nos --impure
}
