" vim:softtabstop=2:shiftwidth=2:et
" Tab preferences
set shiftwidth=2
set softtabstop=2
set autoindent
set expandtab

" Changing the swap directory for the MANPAGER causes a "E302: Could not
" rename swap file" error. Therefore do not change the swap directory for
" man pages.
if stridx(@%, 'man://') >= 0
  " Where to store swap files.  By default, they will go into ~/.vim/swap, but
  " if that doesn't work, they will go in cwd.
  set directory=~/.vim/swap,.
endif

" Turn off vim's mouse stealing.
set mouse=

" Make vim auto-wrap tripple slash comments.
autocmd Filetype c,cpp set comments^=:///

"------------------------------------------------------------------------------
" Plugins
"------------------------------------------------------------------------------

call plug#begin('~/.vim/plugged')

" Highlighting for fish scripts.
Plug 'dag/vim-fish'

" For handling large files.
Plug 'vim-scripts/LargeFile'

" For better file browsing.
Plug 'preservim/nerdtree'

" Supports 'git vimdiff', as well as being handy in its own right.
Plug 'will133/vim-dirdiff'

" There were display/windowing issues with this.
" Plug 'Xuyuanp/nerdtree-git-plugin'

" vim/git integration.
Plug 'tpope/vim-fugitive'

" Use gcc to comment out a line, gc in visual mode to comment out a block.
Plug 'tpope/vim-commentary'

" Highlight and fix whitespace issues.
Plug 'ntpeters/vim-better-whitespace'

" A better status line.
" Might as well use airline since it is more common.
"Plug 'liuchengxu/eleline.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" For fuzzy file searching.
 Plug 'junegunn/fzf', { 'do': { -> fzf#install()  }  }
 Plug 'junegunn/fzf.vim'

" Automatic completion.
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" GitHub Copilot.
Plug 'github/copilot.vim'

" --------------
" Python Plugins
" --------------

" Python syntax highlighting.
Plug 'vim-python/python-syntax'

" Automatic PEP 8 compliance.
Plug 'dense-analysis/ale'

" Automatic quote, paren, and other character pairing.
" REMOVIED: Overall, I found the mistakes this introduced more annoying than
" the help it provided.
"Plug 'jiangmiao/auto-pairs'

" Some Python IDE features such as refactoring.
Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop'  }

" Static type checking.
" REMOVED: I think that Ale and python-mode handle this fine.
"Plug 'integralist/vim-mypy'

" Must be kept last after all Plug commands.
call plug#end()
"------------------------------------------------------------------------------
" End Plugins
"------------------------------------------------------------------------------

"------------------------------------------------------------------------------
" Plugin Configuration
"------------------------------------------------------------------------------

filetype plugin indent on   " enables filetype indent specific plugins

" ---------
" LargeFile
" ---------

" Set the size, in MB, when LargeFile settings should kick in.
let g:LargeFile = 100

" -------
" vimdiff
" -------
set diffopt+=iwhite
if &diff
  colorscheme slate
endif

" --------
" nerdtree
" --------

" Start NERDTree and put the cursor back in the other window.
autocmd VimEnter * NERDTree | wincmd p

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

let NERDTreeIgnore=['\.plist$', '\.o$', '\.lo$', '\.so$', '\.pyc$', '__pycache__', '\~$']

" -------------
" python-syntax
" -------------

let g:python_highlight_all = 1

" ---
" ALE
" ---
let g:ale_linters = {'python': ['flake8', 'pyright', 'pycodestyle', 'pydocstyle']}
let g:ale_python_flake8_options = '--max-line-length 79 --builtins="Test,Condition,Testers,When,ExtendTest,ExtendTestRun,CopyLogic,Any"'

" -----------
" python-mode
" -----------
let g:pymode_options_max_line_length = 79
let g:pymode_rope = 1
let g:pymode_lint_checkers = ['mypy', 'pylint', 'pyflakes', 'pep8', 'mccabe', 'pep257']
let g:pymode_lint_options_pep257 = {'ignore': 'D213'}

" Turn off the error window. The gutter and cursor over information is enough.
let g:pymode_lint_cwindow = 0

" This resolves a conflict with YouCompleteMe (and probably coc).
let g:pymode_rope_completion = 0

" -------------
" YouCompleteMe
" -------------
" Comment this out since the plugin is replaced with coc-vim.
"set encoding=utf-8

" ---
" fzf
" ---
let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -l -g ""'
nnoremap <silent> <leader>z :Files<CR>
nnoremap <silent> <leader>g :Ag<CR>

" -------------
" coc
" -------------

" Set internal encoding of vim, not needed on neovim, since coc.nvim using some
" unicode characters in the file autoload/float.vim
set encoding=utf-8

" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

inoremap <silent><expr> <C-n>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ "\<C-n>"

inoremap <silent><expr> <C-p>
      \ coc#pum#visible() ? coc#pum#prev(1):
      \ "\<C-p>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gc <Plug>(coc-declaration)
" For a function, gd does what you'd think gi would do.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gu <Plug>(coc-references-used)
" clangd-13 does not support the following coc-type-definition. Use gd.
nmap <silent> gy <Plug>(coc-type-definition)

" Mappings to switch between header and cc c++ files.
nmap <silent> gs :CocCommand clangd.switchSourceHeader<CR>
nmap <silent> gS :vsp<CR>:CocCommand clangd.switchSourceHeader<CR>

" Use K to show documentation in preview window.
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>af  <Plug>(coc-fix-current)

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

" To change the error coc popups to be readable.
highlight CocFloating ctermfg=Black ctermbg=DarkYellow
highlight CocErrorFloat ctermfg=Black ctermbg=DarkYellow

"-------------------
" github/copilot.vim
"-------------------
" Uncomment to point to a specific version of node.
"let g:copilot_node_command = "/opt/homebrew/opt/node@16/bin/node"

" Conflicts with the above cov-vim commands.
"inoremap <C-n> <Plug>(copilot-next)
"inoremap <C-p> <Plug>(copilot-previous)

"------------------------------------------------------------------------------
" End Plugin Configuration
"------------------------------------------------------------------------------

" Instructions on how to tab complete filenames.
" set wildmode=longest,list,full
set wildmode=longest,list
set wildmenu

" Turn on line numbers by default.
set number

" Always keep 3 lines of context above and below the curser.
set scrolloff=3

" In case there are vim modelines at the top of the file, as there
" is with this one.
set modeline
set modelines=5

" Always show the status line.
set laststatus=2

" Look for a tags file.
set tags=./tags,tags;
" Also search for .git/tags files.
set tags^=.git/tags;~

" Make Ctrl-] show the list of options by default.
nnoremap <C-]> g<C-]>
nnoremap <C-w>] <C-w>g]

" Colors
" Have syntax highlighting in terminals which can display colours:
if has('syntax') && (&t_Co > 2)
  syntax on
else
  syntax off
endif
set background=dark
set hlsearch
set incsearch

highlight Visual cterm=reverse ctermbg=NONE

" Make *.md files be recognized as markdown instead of modula2.
autocmd BufNewFile,BufFilePre,BufRead *.md set filetype=markdown

" I so often type teh instead of the.
abbreviate teh the

" To help vim deal with pasting text
:map <F9> :set invpaste <CR>
set pt=<F9>

" Toggle vim's spell checker with <F5>
:map <F5> :setlocal spell! spelllang=en_us<cr>

" Shortcuts for c code.
map! ,bc /*  */hhi
map! ,bz #if 0#endif /* 0 */O

" License shortcuts
"    C/C++
map ,cl :0r ~/licenses/LICENSE_c<CR>
"    Python
map ,pl :0r ~/licenses/LICENSE_python<CR>
"    rst files
map ,rl :0r ~/licenses/LICENSE_rst<CR>


" Ignore whitespace when diffing files.
map ,iw :set diffopt+=iwhite<CR>

" Associate some of au test extensions with Python.
au BufRead,BufNewFile *.cli.ext set filetype=python
au BufRead,BufNewFile *.test.ext set filetype=python
au BufRead,BufNewFile *.part set filetype=python
au BufRead,BufNewFile Sconstruct set filetype=python
au BufRead,BufNewFile Makefile.inc set filetype=automake

" Make Y consistent with other capital letter commands (D, C, etc.).
map Y y$
