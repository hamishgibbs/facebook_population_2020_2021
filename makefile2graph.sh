LANG=C make -p | python ./src/makeutils/make_p_to_json.py | python ./src/makeutils/json_to_dot.py | dot -Tpdf >| output/makefilegraph.pdf
