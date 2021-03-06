;; 漢字データベース・異体字管理・検索ユーティリティ

(require 'variants-table)
(require 'ivs-tables)

(defvar variants-name
  '((compat/variant . "互換漢字")
    (kdp/duplicate . "重複漢字")
    (hydcd/ic . "通假字表")
    (hydzd/variant . "異体字（漢語大詞典）")
    (hydzd/simplified . "簡体字（漢語大詞典）")
    (hydzd/complex . "繁体字（漢語大詞典）")
    (hydzd/regular . "正字（漢語大詞典）")
    (hyogai/variant . "表外字")
    (jinmei1/variant . "人名用漢字（別表１）")
    (jinmei2/variant . "人名用漢字（別表２）")
    (jisx0212/variant . "JIS X 0212 異体字")
    (jisx0213/variant . "JIS X 0213 異体字")
    (joyo/regular . "常用漢字")
    (joyo/variant . "異体字（常用漢字表）")
    (jp/ic . "同音の書換可能")
    (kdp/simplified . "簡化字総表（表１）")
    (kdp/simplified/p . "簡化字総表（简化偏旁表）")
    (kdp/simplified/d . "第一批異体字整理表")
    (kdp/simplified/1956 . "第一批異体字整理表（1956年廃止）")
    (kdp/simplified/1988 . "第一批異体字整理表（1988年廃止）")
    (kdp/simplified/1993 . "第一批異体字整理表（1993年廃止）")
    (kdp/simplified/1997 . "第一批異体字整理表（1997年廃止確認）")
    (kdp/simplified/s . "原規格分離規則")
    (kdp/simplified/e . "原規格分離規則に準じる漢字")
    (kdp/simplified . "その他の簡体字")
    (kdp/simplified/G0 . "GB2312記載字")
    (kdp/simplified/G2 . "GB7589記載字")
    (kdp/simplified/G4 . "GB7590記載字")
    (kdp/simplified/X . "類推簡化字")
    (kdp/traditional . "繁体字")
    (kdp/traditional/p "繁体字（簡化字総表・简化偏旁）")
    (kdp/traditional/d . "繁体字（第一批異体字整理表）")
    (kdp/variants/d .  "異体字（第一批異体字整理表）")
    (kdp/traditional/s . "繁体字（原規格分離規則）")
    (kdp/traditional/e . "繁体字（原規格分離規則に準じる漢字）")
    (kdp/traditional/X . "繁体字（類推）")
    (non-cjkui/radical . "非漢字（部首）")
    (non-cjkui/regular . "漢字")
    (non-cjkui/kangxi .  "非漢字（康煕部首）")
    (non-cjkui/hangzhou-num . "非漢字（杭州数字）")
    (non-cjkui/katakana . "カタカナ")
    (non-cjkui/bopomofo . "ボポモフォ")
    (non-cjkui/super . "漢文など")
    (non-cjkui/parenthesized . "カッコ付き")
    (non-cjkui/circle . "◯囲み")
    (non-cjkui/square . "□囲み")
    (non-cjkui/bracketed . "括弧付き")
    (kdp/variant/positional . "相対位置の差異")
    (radical/variant . "部首異体字")
    (radical/regular . "正字")
    (ucs-scs/variant . "原規格分離")
    (yyb/variant . "異体字（第一批異体字整理表）")
    (yyb/regular . "異体字（第一批異体字整理表）")
    (yyb/variant/1956 . "異体字（第一批異体字整理表）1956年廃止")
    (yyb/regular/1956 . "正字（第一批異体字整理表）1956年廃止")
    (yyb/variant/1986 . "異体字（第一批異体字整理表）1986年廃止")
    (yyb/regular/1986 . "正字（第一批異体字整理表）1986年廃止")
    (yyb/variant/1988 . "異体字（第一批異体字整理表）1988年廃止")
    (yyb/regular/1988 . "正字（第一批異体字整理表）1988年廃止")
    (yyb/variant/1993 . "異体字（第一批異体字整理表）1993年廃止")
    (yyb/regular/1993 . "正字（第一批異体字整理表）1993年廃止")
    (yyb/variant/1997 . "異体字（第一批異体字整理表）1997年廃止")
    (yyb/regular/1997 . "正字（第一批異体字整理表）1997年廃止")
    (kdp/variant . "そのほかの異体字")))

;; calculation

(defun variants-char-table (char)
  (let ((variants (aref variants-table char))
        attr chars
        (table (make-hash-table)))
    (while variants
      (setq attr (car variants)
            chars (cadr variants)
            variants (cddr variants))
      (when (not (listp chars)) (setq chars (list chars)))
      (dolist (char chars)
        (setq entry (gethash char table))
        (push attr entry)
        (puthash char entry table)))
    table))

(defun variants-by-category (char prop-regexp)
  (let ((plist (aref variants-table char))
        result)
    (while plist
      (let ((prop (symbol-name (car plist)))
            (chars (cadr plist)))
        (setq plist (cddr plist))
        (if (string-match prop-regexp prop)
            (if (listp chars)
                (setq result (append result chars))
              (setq result (append result (list chars)))))))
    (remove-duplicates result :test 'equal)))

(defun variants-list-to-string (list)
  (apply 
   'concat
   (mapcar (lambda (x) (if (characterp x) (char-to-string x)
                         x)) list)))

(defun variants (char)
  (let ((regular  (variants-by-category char "/regular"))
        (complex  (variants-by-category char "/complex"))
        (simpl    (variants-by-category char "/simplified"))
        (variants (variants-by-category char "/variant"))
        (component (variants-by-category char "^../."))
        (ic       (variants-by-category char "/ic")))
    ;; variants = variants-regular--complex-simpl
    (setq variants (set-difference variants regular :test 'equal)
          variants (set-difference variants complex :test 'equal)
          variants (set-difference variants simpl  :test 'equal))
    ;; components = components-regular-complex-simpl-simpl
    (setq component (set-difference component regular :test 'equal)
          component (set-difference component complex :test 'equal)
          component (set-difference component simpl :test 'equal)
          component (set-difference component variants :test 'equal))
    (concat (if (or regular complex simpl variants component) "《")
            (if regular (concat (variants-list-to-string regular) "|"))
            (if complex (concat (variants-list-to-string complex) "|"))
            (if simpl (concat (variants-list-to-string simpl) ">"))
            (if variants (variants-list-to-string variants))
            (if component (concat "<" (variants-list-to-string component)))
            ;;(if ic (concat "<" (variants-list-to-string ic)))
            (if (or regular simpl variants component) "》")
            )))

;; ###autoload
(defun variants-find (char)
  (let ((regular  (variants-by-category char "/regular"))
        (simpl    (variants-by-category char "/simplified"))
        (variants (variants-by-category char "/variant"))
        (complex  (variants-by-category char "/complex"))
        (component (variants-by-category char "^../.")))
    (remove-duplicates 
     (append regular simpl variants complex component )
          :test 'equal)))

;;;###autoload
(defun variants-insert ()
  (interactive)
  (insert (variants (char-after (point)))))

(provide 'variants)    
