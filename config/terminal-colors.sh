# Interactive shells only: restore color when launched by an agent with NO_COLOR.
case $- in
  *i*)
    if [ "${TERM_PROGRAM:-}" = WezTerm ] || [ "${HERDR_ENV:-}" = 1 ]; then
      unset NO_COLOR
      export COLORTERM=truecolor
    fi
    ;;
esac
