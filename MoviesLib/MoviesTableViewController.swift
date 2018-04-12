//
//  MoviesTableViewController.swift
//  MoviesLib
//
//  Created by Eric on 24/03/17.
//  Copyright © 2017 EricBrito. All rights reserved.
//

import UIKit
import CoreData

class MoviesTableViewController: UITableViewController {

    //Criando nossa label que será a backgroundView da tabela
    var label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 22))
    
    var fetchedResultController: NSFetchedResultsController<Movie>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 106  //Definindo um tamanho base para o cálculo do tamanho final
        tableView.rowHeight = UITableViewAutomaticDimension //Definindo que o tamanho será dinâmico

        //Definindo os valores das propriedades da lavel
        label.text = "Sem filmes"
        label.textAlignment = .center
        label.textColor = .white
        
        loadMovies()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MovieViewController {
            vc.movie = fetchedResultController.object(at: tableView.indexPathForSelectedRow!)
        }
    }
    
    func loadMovies() {
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        
        do {
            try fetchedResultController.performFetch()
        } catch {
            print(error.localizedDescription)
        }
        
    }


    // MARK: - Table view data source

    //Método que define a quantidade de seções de uma tableView
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Método que define a quantidade de células para cada seção de uma tableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let count = fetchedResultController.fetchedObjects?.count {
            tableView.backgroundView = count == 0 ? label : nil
            return count
        } else {
            tableView.backgroundView = label
            return 0
        }
    }
    
    //Método que define a célula que será apresentada em cada linha
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Definimos o identifier que usamos em nossa célula (movieCell)
        //Fazemos o cast para MovieTableViewCell para que possamos acessar os
        //IBOutlets criados
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieCell", for: indexPath) as! MovieTableViewCell
        
        let movie = fetchedResultController.object(at: indexPath)
        
        //Atribuindo os valores de acordo com os dados recuperados de cada Movie
        //Recuperamos o Movie usando a propriedade row do indexPath da célula em questão
        
        cell.ivPoster.image = movie.poster
        cell.lbTitle.text = movie.title
        cell.lbRating.text = "\(movie.rating)"
        cell.lbSummary.text = movie.summary
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */
    
    // Override to support editing the table view.

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            // tableView.deleteRows(at: [indexPath], with: .fade)
            
            let movie = fetchedResultController.object(at: indexPath)
            do {
                context.delete(movie)
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }


    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension MoviesTableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        tableView.reloadData()
        
    }
}

















