vim.cmd('source ~/.config/nvim/vimrc.vim')
-- Chemin du fichier colors-wal à surveiller
local filepath = vim.fn.expand("~/.config/nvim/colors/colors-wal.vim")

-- Récupère les infos actuelles du fichier
local stat = vim.loop.fs_stat(filepath)
if not stat then
  print("Fichier colors-wal introuvable : " .. filepath)
  return
end

-- Stocke la date de dernière modification du fichier
local last_modified = stat.mtime.sec

-- Crée un timer (libuv) pour vérifier les changements
local timer = vim.loop.new_timer()

-- Démarre le timer : 0 = pas de délai, 2000 = toutes les 2 secondes
timer:start(0, 2000, vim.schedule_wrap(function()
  local new_stat = vim.loop.fs_stat(filepath)
  if not new_stat then return end

  -- Compare le nouveau mtime à l'ancien
  if new_stat.mtime.sec ~= last_modified then
    last_modified = new_stat.mtime.sec
    vim.cmd("colorscheme colors-wal")
    vim.cmd("redraw!")
    print("[nvim] Thème colors-wal mis à jour")
  end
end))

