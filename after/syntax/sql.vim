" Дополнительная подсветка PostgreSQL поверх стандартного syntax/sql.vim
" (после файла из runtime, поэтому добавляет, а не переопределяет).
if !exists('b:current_syntax')
  finish
endif

syn case ignore

" --- ключевые слова PostgreSQL -------------------------------------------------
syn keyword sqlPgKeyword returning excluded conflict nothing filter over partition
syn keyword sqlPgKeyword lateral unnest generate_series tablesample
syn keyword sqlPgKeyword ilike similar array any all some
syn keyword sqlPgKeyword jsonb json jsonpath tsvector tsquery
syn keyword sqlPgKeyword uuid serial bigserial smallserial identity
syn keyword sqlPgKeyword timestamptz numeric money bytea inet cidr macaddr
syn keyword sqlPgKeyword materialized concurrently recursive
syn keyword sqlPgKeyword vacuum analyze reindex cluster listen notify
syn keyword sqlPgKeyword extension policy trigger function procedure do
syn keyword sqlPgKeyword gin gist btree brin hash tablespace owner grant
syn keyword sqlPgKeyword sequence generated always stored virtual
syn keyword sqlPgKeyword declared strict immutable stable volatile
syn keyword sqlPgKeyword language plpgsql returns perform raise
syn keyword sqlPgKeyword notice exception elsif loop foreach
syn keyword sqlPgKeyword cascade restrict deferrable initially

" --- типы ---------------------------------------------------------------------
syn keyword sqlPgType integer bigint boolean text varchar citext numeric
syn keyword sqlPgType timestamptz timestamp interval date time
syn keyword sqlPgType jsonb json uuid bytea inet cidr macaddr hstore

" --- функции ------------------------------------------------------------------
syn keyword sqlPgFunction now clock_timestamp current_date current_timestamp
syn keyword sqlPgFunction coalesce nullif greatest least
syn keyword sqlPgFunction array_agg string_agg json_agg jsonb_agg
syn keyword sqlPgFunction jsonb_build_object jsonb_set json_build_object
syn keyword sqlPgFunction to_char to_date to_timestamp date_trunc extract age
syn keyword sqlPgFunction row_number rank dense_rank percent_rank
syn keyword sqlPgFunction lag lead first_value last_value ntile
syn keyword sqlPgFunction gen_random_uuid random sum count avg min max

" --- операторы -----------------------------------------------------------------
syn match sqlPgCast /::/
syn match sqlPgJsonOp /->>\|->\|#>>\|#>\|@>\|<@/
syn match sqlPgOperator /\<SIMILAR\ TO\>/ contained
syn match sqlPgDollar /\$\w*\$/ display

" --- psql-метакоманды ---------------------------------------------------------
syn match sqlPgMeta /^\s*\zs\\[[:alpha:]?]\+/ display

hi def link sqlPgKeyword Statement
hi def link sqlPgType Type
hi def link sqlPgFunction Function
hi def link sqlPgCast Special
hi def link sqlPgJsonOp Special
hi def link sqlPgOperator Statement
hi def link sqlPgDollar Delimiter
hi def link sqlPgMeta PreProc

" vim: sw=2 sts=2 ts=4 noet
