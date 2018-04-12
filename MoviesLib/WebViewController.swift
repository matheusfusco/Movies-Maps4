//
//  WebViewController.swift
//  MoviesLib
//
//  Created by Eric Brito on 27/03/17.
//  Copyright © 2017 EricBrito. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
    var url: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.scrollView.bounces = true           //Define se a webView "quica" ou não
        let webPageURL = URL(string: url!)           //Preparando a URL com a página
        let request = URLRequest(url: webPageURL!)  //Criando a requisição que será feita
        webView.loadRequest(request)                //Efetuando a requisição na webView
        webView.delegate = self                     //Esta classe será a delegate da WebView
    }

    @IBAction func runJS(_ sender: UIBarButtonItem) {
        
        //O método abaixo recebe comandos Javascript em formato de String e executa na WebView
        webView.stringByEvaluatingJavaScript(from: "alert('Rodando Javascript na WebView')")
        
        //Como não criamos um botão para voltar à tela anterior, vamos agendar a execução
        //de um código para sair da tela em 3.0 segundos. Para isso, usamos a classe Timer
        //e executamos seu método de classe abaixo. Note que o comando que o timer executará
        //não se repetirá (repeats: false)
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer:Timer) in
            self.dismiss(animated: true, completion: nil)
        }
    }

}

//Implementando o protocolo UIWebViewDelegate
extension WebViewController: UIWebViewDelegate {
    
    //Método que define se uma requisição deve ou não ser executada
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        //Caso a url da requisição contenha a palavra "ads", impedimos sua execução
        if request.url!.absoluteString.range(of: "ads") != nil { return false }
        return true
    }
    
    //Método disparado quando as WebView finalizou o carregamento do seu conteúdo
    func webViewDidFinishLoad(_ webView: UIWebView) {
        loading.stopAnimating()
    }
}

