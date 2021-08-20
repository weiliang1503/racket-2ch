#lang racket

(require web-server/servlet)
(require web-server/servlet-env)
(require "db.rkt")

;;(displayln (get-page-posts 1))

;;主服务器函数
(define (main-server req)
  ;;(displayln req)
  ;;获得get请求的参数，如页数，是否要求单个帖子
  (define p 1)
  (define n #f)
  (for ((i (url-query (request-uri req))))
    (when (symbol=? (car i) 'p)
      (set! p (string->number (cdr i))))
    (when (symbol=? (car i) 'n)
      (set! n (string->number (cdr i)))))
  (when (< p 1) (set! p 1))

  ;;构建主体
  (define back '())

  (cond (n
         (for ((post (get-post n)));单个帖子
           (set! back (append back
                              (list `(div ((class "card"))
                                          (div ((class "card-body"))
                                               (h5 ((class "card-title")) ,(vector-ref post 1))
                                               (p ((class "card-text")) ,(vector-ref post 2))
                                               (p ((class "card-text")) (small ,(vector-ref post 3))))))
                              '((br))))))
        (else
         (for ((post (get-page-posts p)))
           (set! back (append back
                              (list `(div ((class "card"))
                                          (div ((class "card-body"))
                                               (h5 ((class "card-title")) (a ((href ,(format "/?n=~A" (vector-ref post 0))))  ,(vector-ref post 1)))
                                               (p ((class "card-text")) ,(vector-ref post 2))
                                               (p ((class "card-text")) (small ,(vector-ref post 3))))))
                              '((br)))))))

  ;;回调函数，用于增加帖子
  (define (new-post request)
    (define name "")
    (define words "")
    ;;(displayln (request-bindings request))
    (for ((i (request-bindings request)))
      (when (symbol=? (car i) 'name)
        (set! name (cdr i)))
      (when (symbol=? (car i) 'words)
        (set! words (cdr i))))
    (when (and (not (string=? name "")) (not (string=? words "")))
      (add-post name words))
    (main-server (redirect/get)))

  ;;返回页面
  (send/suspend/dispatch
   (lambda (embed/url)
     (define body (append `(div ((class "container"))
                                (br)
                                (h1 (a ((href "/")) "朝色の2ch"))
                                (br)
                                (form ((action
                                        ,(embed/url new-post)))
                                      (div ((class "input-group mb-3"))
                                           (div ((class "input-group-prepend"))
                                                (span ((class "input-group-text") (id "basic-addon1")) "昵称"))
                                           (input ((type "text") (class "form-control") (placeholder "昵称") (name "name")))
                                           (input ((type "submit") (class "form-control"))))
                                      (div ((class "input-group"))
                                           (div ((class "input-group-prepend"))
                                                (span ((class "input-group-text")) "内容"))
                                           (textarea ((class "form-control") (name "words"))))))
                          back
                          `((p ,(format "现在是第~A页" p))
                            (p (a ((href ,(format "/?p=~A" (- p 1)))) "<上一页<")

                               (a ((href ,(format "/?p=~A" (+ p 1)))) ">下一页>")))))

     ;;(displayln back)

     (response/xexpr `(html (head (title "朝色の2ch")
                                  ;; (mate ((charset "utf-8")))
                                  ;; (meta ((name "viewport") (content "width=device-width, initial-scale=1")))
                                  (link ((rel "stylesheet") (href "/bootstrap.css")))
                                  (script ((src "/bootstrap.js"))))
                                 ,body)))))

(serve/servlet main-server
               #:port 8080
               #:listen-ip "0.0.0.0"
               #:servlet-path "/"
               #:extra-files-paths (list
                                    (build-path "./btsp")))

